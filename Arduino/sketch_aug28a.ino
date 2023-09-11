#define BLUE_PIN   32
#define GREEN_PIN 25

bool flashing = false; // 用於追踪LED是否在閃爍
char currentColor = ' '; // 目前LED的顏色

void setup() {
  pinMode(BLUE_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);

  // 設置初始狀態為全部關閉（因為是共陽，所以HIGH是關閉）
  digitalWrite(BLUE_PIN, HIGH);
  digitalWrite(GREEN_PIN, HIGH);

  Serial.begin(9600); // 開始串口通訊，波特率設為9600
}

void loop() {
  if (Serial.available()) { // 檢查是否有資料在串口緩衝區
    char c = Serial.read(); // 讀取字符

    switch (c) {
      case 'g': // 綠色亮
        digitalWrite(GREEN_PIN, LOW);
        digitalWrite(BLUE_PIN, HIGH);
        currentColor = 'e';
        flashing = false;
        break;

      case 'b': // 藍色亮
        digitalWrite(BLUE_PIN, LOW);
        digitalWrite(GREEN_PIN, HIGH);
        currentColor = 'c';
        flashing = false;
        break;

      case 'L': // 開始閃爍
        flashing = true;
        break;

      case 'l': // 停止閃爍
        flashing = false;
        break;

      default: // 其他情況，全部關閉
        digitalWrite(BLUE_PIN, HIGH);
        digitalWrite(GREEN_PIN, HIGH);
        currentColor = ' ';
        flashing = false;
        break;
    }
  }

  if (flashing) {
    // 閃爍模式
    if (currentColor == 'e') {
      digitalWrite(GREEN_PIN, !digitalRead(GREEN_PIN));
    } else if (currentColor == 'c') {
      digitalWrite(BLUE_PIN, !digitalRead(BLUE_PIN));
    }
    delay(100);
  }
}
