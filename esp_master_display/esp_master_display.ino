#define SDA 21
#define SCL 22
#define BTN1 27 // back
#define BTN2 26 // up
#define BTN3 25 // down
#define BTN4 33 // select

#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

// menu structure
struct Menu {
  const char* title;
  const char** options;
  int optionCount;
  Menu* subMenus;
};

const char* mainOptions[] = {"Settings", "About", "Info"};
const char* settingsOptions[] = {"Option 1", "Option 2", "Option 3"};
const char* aboutOptions[] = {"Version", "Credits"};
const char* infoOptions[] = {"Data 1", "Data 2", "Data 3", "Data 4"};

Menu settingsMenu = {"Settings", settingsOptions, 3, nullptr};
Menu aboutMenu = {"About", aboutOptions, 2, nullptr};
Menu infoMenu = {"Info", infoOptions, 4, nullptr};

Menu mainSubMenus[] = {settingsMenu, aboutMenu, infoMenu};

Menu mainMenu = {"Main Menu", mainOptions, 3, mainSubMenus};

Menu* currentMenu = &mainMenu;
int selectedIndex = 0;

// debounce settings
unsigned long lastButtonPress = 0;
const unsigned long debounceDelay = 200; // milliseconds

void setup() {
  pinMode(BTN1, INPUT_PULLUP);
  pinMode(BTN2, INPUT_PULLUP);
  pinMode(BTN3, INPUT_PULLUP);
  pinMode(BTN4, INPUT_PULLUP);

  lcd.init();
  lcd.backlight();
  drawMenu();
}

void drawMenu() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(currentMenu->options[selectedIndex]);
}

void loop() {
  unsigned long currentTime = millis();

  if (currentTime - lastButtonPress > debounceDelay) {
    if (digitalRead(BTN2) == LOW) { // up
      selectedIndex--;
      if (selectedIndex < 0) selectedIndex = 0;
      drawMenu();
      lastButtonPress = currentTime;
    }
    if (digitalRead(BTN3) == LOW) { // down
      selectedIndex++;
      if (selectedIndex >= currentMenu->optionCount) selectedIndex = currentMenu->optionCount - 1;
      drawMenu();
      lastButtonPress = currentTime;
    }
    if (digitalRead(BTN4) == LOW) { // select
      if (currentMenu->subMenus != nullptr) {
        currentMenu = &currentMenu->subMenus[selectedIndex];
        selectedIndex = 0;
        drawMenu();
      }
      lastButtonPress = currentTime;
    }
    if (digitalRead(BTN1) == LOW) { // back
      if (currentMenu != &mainMenu) {
        currentMenu = &mainMenu;
        selectedIndex = 0;
        drawMenu();
      }
      lastButtonPress = currentTime;
    }
  }
}
