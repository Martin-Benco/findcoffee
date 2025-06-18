# Fonts pre Coffit

Sem vlož všetky .ttf alebo .otf súbory fontov, ktoré chceš použiť v aplikácii.

Nezabudni ich zaregistrovať v pubspec.yaml napríklad takto:

fonts:
  - family: Inter
    fonts:
      - asset: lib/core/fonts/Inter-Regular.ttf
      - asset: lib/core/fonts/Inter-Bold.ttf
        weight: 700 