; Simple program for the PCB-0001-0A PCB
;
; Program will set RC5 as output and set high
;

    list p=16lf1509
    #include <p16lf1509.inc>

        __CONFIG _CONFIG1, _FOSC_ECH & _WDTE_OFF & _PWRTE_OFF & _CLKOUTEN_OFF & _BOREN_OFF & _CP_OFF
        __CONFIG _CONFIG2, _WRT_OFF & _LVP_OFF & _STVREN_ON


;Some bits that aren't defined in the header?
TMR2IF  equ 0x01
ADIE    equ 0x06
ADIF    equ 0x06
PEIE    equ 0x06
GIE     equ 0x07

counter             equ 0x70    ; In common bank memory
nextSPIbyte         equ 0x71    ; Store for next data to send
incomingSPIbyte     equ 0x72    ; Data send to SPI from Master
dataPointerISR      equ 0x73    ; Keeps the data pointer for SPI during interrupt( any changes from interrupt are destroyed by poping stack)
sendAnotherFF       equ 0x74    ; Is set after first FF, to indicate second needs sent

#define ledON   bsf PORTC, 5
#define ledOFF  bcf PORTC, 5

;------------------------------------------------------------------------------
        ORG 0x00    ; reset vector
resetvect
        nop
        goto main


;------------------------------------------------------------------------------
        ORG 0x04        ;Interrupt Vector - SPI Complete and needs next data byte fed in
intvect
        BANKSEL PIR1
        bcf     PIR1, 3 ; Clear the SSPIF interrupt flag

        BANKSEL SSP1BUF ; Grab incoming data
        movf    SSP1BUF, w
        movwf   incomingSPIbyte

        
        movf    nextSPIbyte, w   ; Set up buffer with data!
        movwf   SSP1BUF


        ;If dataPointer has caught up with FSR0H then insert 0x7E and exit
        movlw   0x7E
        movwf   nextSPIbyte

        movf    dataPointerISR, w
        subwf   FSR0L, w
        btfsc   STATUS, Z
        goto    exitISR


        ;Load nextSPIbyte  data from the circular buffer
        movf    dataPointerISR, w
        movwf   FSR1L           ;Set up the FSR1 pointer, This will reset on exit from interrupt
        movf    INDF1, w
        movwf   nextSPIbyte
        incf    dataPointerISR

exitISR
        retfie



;-------------------------------------------------------------------------------
init

initialise_ports
        BANKSEL ANSELA
        clrf    ANSELA          ;All Digital Pins
        clrf    ANSELC

        BANKSEL TRISC
        bcf     TRISC, 5        ;RC5, LED on board as output

      ;  BANKSEL OSCCON
      ;  movlw   0x78
      ;  movwf   OSCCON          ;go to 16MHz clock (External Oscillator in Use)

; Configure timer 2
initialise_timer2
        BANKSEL PR2             ;For 20MHz oscillator
        movlw   0x61            ;Compare Register for Timer 2 0x61=DEC 97 97+1=98, 125000000/98=12755.1020408Hz sample rate
        movwf   PR2             ;1:4 Prescale

        BANKSEL T2CON
        clrf    T2CON
        bcf     T2CON, 1
        bsf     T2CON, 0        ;1:4 prescaler
        bsf     T2CON, 2        ;Turn Timer 2 on

initialise_ADC
;1. Configure Port:
;? Disable pin output driver (Refer to the TRIS register)
;? Configurepinasanalog(RefertotheANSEL register)
        BANKSEL TRISA
        BSF     TRISA, 2        ;RA2 (AN2) (pin 17) as Input pin
        ;BSF     TRISA, 1        ;RA1 (AN1) (pin 12) as Input pin

        BANKSEL ANSELA
        bsf     ANSELA, 2       ;Set pin as Analog


;2. Configure the ADC module:
;? SelectADCconversionclock ? Configurevoltagereference ? SelectADCinputchannel
;? TurnonADCmodule
        BANKSEL ADCON1
        movlw   B'11010000'            ;Right Justified; Fosc/16; Vref+=Vdd
        movwf   ADCON1

        BANKSEL ADCON2
        movlw   B'01010000'            ;TMR2 match PR2 Autoconversion Trigger
        movwf   ADCON2

        BANKSEL ADCON0
        movlw   B'00001001'             ;Channel AN2, ADC Enable
        movwf   ADCON0

;3. Configure ADC interrupt (optional): ? ClearADCinterruptflag
;? EnableADCinterrupt
;? Enableperipheralinterrupt
;? Enableglobalinterrupt(1)

        BANKSEL PIE1
        bcf     PIE1,   ADIE              ; Disable the AD module interrupt

        BANKSEL PIR1
        bcf     PIR1,   ADIF              ; Clear the interrupt Flag

        BANKSEL INTCON
        bsf     INTCON, PEIE
        bsf     INTCON, GIE

;initialise MSSP for SPI slave mode with interrupt
;
;
        clrf    nextSPIbyte;

        BANKSEL TRISB
        bsf     TRISB,  4   ;   MOSI
        bsf     TRISB,  6   ;   SCLK

        BANKSEL TRISC
        bsf     TRISC,  6   ;   SSEN/N
        bcf     TRISC,  7   ;   MISO

        BANKSEL SSP1STAT
        bcf     SSP1STAT, 7     ;SMP=0  SPI Data Input Sample - Must be clear when in SPI Slave mode
        bsf     SSP1STAT, 6     ;CK=0   Transmit occurs on transition from active to idle clock state

        BANKSEL SSP1CON1
        movlw   B'00100100'     ;MSSP Enabled, Clock idle Low, SPI Slave mode, Clock=SCKx pin, SSP/N Enabled
        movwf   SSP1CON1
        
        clrf    dataPointerISR; ;Start the data pointer from 0x00 offset in buffer!

        BANKSEL PIE1
        bsf     PIE1, 3         ;SSP1IE=1 Enable the interrupt from SPI

        return

;------------------------------------------------------------------------------
main

initalise
    banksel TRISC
    bcf     TRISC, 5    ; Make RC5 an output
   
    call    init        ; Goto initialisation code

fsrtest

        movlw   0x20    ; Initialise FSR pointers to start of Linear Space
        movwf   FSR0H   ; Idea is to use low byte, continue to increment,
        movwf   FSR1H   ; Will wrap round in a 255 byte circular buffer
        clrf    FSR0L   ; Write pointer (AD results written in)
        clrf    FSR1L   ; SPI Device Samples out



;Main loop checks for A/D result and enters results into buffer
checkAD

        BANKSEL PIR1
        btfss   PIR1,    ADIF
cd         goto checkAD

;A/D interrupt flag set, so clear it
        BANKSEL PIR1
        bcf     PIR1,    ADIF

       BANKSEL ADRESH
              ;Write A/D result and increment
        movf    ADRESH, w
        movwf   INDF0
        incf    FSR0L


        ;If AD result low = 0x7E then insert sequence 0x7D 0x5E
        movf    ADRESL, w
        sublw   0x7E
        btfss   STATUS, Z
        goto    checkfor0x7D


escapeSequenceWrite0x7E
        movlw   0x7D
        movwf   INDF0
        incf    FSR0L
        movlw   0x5E
        movwf   INDF0
        incf    FSR0L
        goto    checkAD

checkfor0x7D
        movf    ADRESL, w
        sublw   0x7D
        btfss   STATUS, Z
        goto    normalwrite

escapeSequenceWrite0x7D
        movlw   0x7D
        movwf   INDF0
        incf    FSR0L
        movlw   0x5D
        movwf   INDF0
        incf    FSR0L
        goto    checkAD


        goto    checkAD
normalwrite
        movf    ADRESL, w
        movwf   INDF0
        incf    FSR0L
        goto    checkAD

    end


