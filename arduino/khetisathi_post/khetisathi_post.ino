// KhetiSathi sensor post: Arduino Nano + PIR + DFPlayer Mini
// Library: DFRobotDFPlayerMini (install from Arduino Library Manager)
#include <SoftwareSerial.h>
#include <DFRobotDFPlayerMini.h>

const int PIR_PIN    = 2;    // HC-SR501 OUT
const int STROBE_PIN = 6;    // MOSFET module -> 12 V LED light
const int SIREN_PIN  = 7;    // relay module -> 12 V siren (optional)
const int TRACKS     = 6;    // number of sounds on SD card: 0001.mp3 ... 0006.mp3
const unsigned long SCARE_MS    = 8000;   // scare length
const unsigned long COOLDOWN_MS = 25000;  // wait before next scare

SoftwareSerial dfSerial(10, 11);          // RX, TX (TX -> DFPlayer RX via 1k resistor)
DFRobotDFPlayerMini player;
unsigned long lastScare = 0;
int lastTrack = 0;

void setup() {
  pinMode(PIR_PIN, INPUT);
  pinMode(STROBE_PIN, OUTPUT);
  pinMode(SIREN_PIN, OUTPUT);
  dfSerial.begin(9600);
  player.begin(dfSerial);
  player.volume(30);                      // 0 to 30
  randomSeed(analogRead(A0));
  delay(30000);                           // PIR warm-up
}

void scare() {
  int track;
  do { track = random(1, TRACKS + 1); } while (track == lastTrack && TRACKS > 1);
  lastTrack = track;                      // never the same sound twice in a row
  player.play(track);
  bool useSiren = random(0, 3) == 0;      // siren only sometimes
  if (useSiren) digitalWrite(SIREN_PIN, HIGH);
  unsigned long start = millis();
  while (millis() - start < SCARE_MS) {   // uneven flashing is harder to get used to
    digitalWrite(STROBE_PIN, HIGH); delay(60 + random(0, 90));
    digitalWrite(STROBE_PIN, LOW);  delay(60 + random(0, 160));
  }
  digitalWrite(SIREN_PIN, LOW);
  player.stop();
  lastScare = millis();
}

void loop() {
  if (digitalRead(PIR_PIN) == HIGH && millis() - lastScare > COOLDOWN_MS) {
    scare();
  }
  delay(50);
}
