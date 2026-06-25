/*
  error_alert.ino
  -----------------------------------------------------------------
  Error Alert System - Arduino UNO R3

  Listens on USB serial for a single command byte:
    'E'  -> run the alert sequence:
            1. Servo moves from 0deg -> 180deg
            2. DFPlayer Mini plays 0001.mp3 (from SD card root)
            3. Hold for 10 seconds
            4. Stop playback
            5. Servo moves back to 0deg

  -------------------------------------------------------------------------
  WIRING
  -------------------------------------------------------------------------
  Servo (e.g. SG90):
    Signal -> D9
    VCC    -> 5V
    GND    -> GND

  DFPlayer Mini:
    VCC      -> 5V
    GND      -> GND
    RX       -> D11  (recommended: through a 1k ohm resistor)
    TX       -> D10
    SPK_1/2  -> Speaker

  SD Card:
    Place a file named "0001.mp3" in the ROOT of the SD card.

  -------------------------------------------------------------------------
  LIBRARIES REQUIRED (install via Arduino IDE Library Manager)
  -------------------------------------------------------------------------
    - Servo                  (built-in)
    - SoftwareSerial          (built-in)
    - DFRobotDFPlayerMini     (by DFRobot)
*/

#include <Servo.h>
#include <SoftwareSerial.h>
#include <DFRobotDFPlayerMini.h>

#define SERVO_PIN   9
#define DF_RX_PIN   10   // Arduino RX  <- DFPlayer TX
#define DF_TX_PIN   11   // Arduino TX  -> DFPlayer RX

#define SERVO_REST_ANGLE  0
#define SERVO_ALERT_ANGLE 180
#define ALERT_HOLD_MS     4000UL   // 4 seconds
#define DF_TRACK_NUMBER   1         // plays 0001.mp3
#define DF_VOLUME         25        // 0-30

Servo alertServo;
SoftwareSerial dfSerial(DF_RX_PIN, DF_TX_PIN);
DFRobotDFPlayerMini dfPlayer;

bool dfReady = false;

void setup() {
  Serial.begin(9600);
  dfSerial.begin(9600);

  alertServo.attach(SERVO_PIN);
  alertServo.write(SERVO_REST_ANGLE);

  dfReady = dfPlayer.begin(dfSerial);
  if (dfReady) {
    dfPlayer.volume(DF_VOLUME);
  }

  Serial.println(F("Error Alert System ready."));
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  if (Serial.available() > 0) {
    char cmd = Serial.read();
    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);

    if (cmd == 'E' || cmd == 'e') {
      runAlert();
    }
  }
}

void runAlert() {
  // 1. Servo to alert position
  alertServo.write(SERVO_ALERT_ANGLE);

  // 2. Play 0001.mp3
  if (dfReady) {
    dfPlayer.play(DF_TRACK_NUMBER);
  }

  // 3. Hold for 4 seconds
  delay(ALERT_HOLD_MS);

  // 4. Stop sound
  if (dfReady) {
    dfPlayer.stop();
  }

  // 5. Servo back to rest position
  alertServo.write(SERVO_REST_ANGLE);
}
