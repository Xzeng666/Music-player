QT       += core gui
QT       += core gui multimedia
QT       += multimedia


greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++17

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0
RC_ICONS = "Icon\music.ico"
SOURCES += \
    main.cpp \
    mainwindow.cpp

HEADERS += \
    mainwindow.h

FORMS += \
    mainwindow.ui

TRANSLATIONS += \
    MusicPlayer_zh_CN.ts
CONFIG += lrelease
CONFIG += embed_translations

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    Icon/list.png \
    Icon/loop.png \
    Icon/next.png \
    Icon/order.png \
    Icon/play.png \
    Icon/prev.png \
    Icon/random.png \
    Icon/stop.png \
    Music/Embers.mp3 \
    Music/Embers.mp3 \
    Music/Mood (Lil Ghost RemixExplicit).mp3 \
    Music/Mood (Lil Ghost RemixExplicit).mp3 \
    Music/Mood (Lil Ghost RemixExplicit).mp3 \
    Music/カタオモイ-Aimer.mp3 \
    Music/稻香-周杰伦.mp3 \
    images/background (1).jpg \
    images/background (1).jpg \
    images/background (1).jpg \
    images/background (2).jpg \
    images/background (2).jpg \
    images/background (2).jpg \
    images/background (3).jpg \
    images/background (3).jpg \
    images/background (3).jpg \
    images/background (4).jpg \
    images/background (4).jpg \
    images/background (4).jpg \
    images/background (5).jpg \
    images/background (5).jpg \
    images/background (5).jpg \
    images/background (6).jpg \
    images/background (6).jpg \
    images/background (6).jpg \
    images/background (7).jpg \
    images/background (7).jpg \
    images/background (7).jpg \
    images/background (8).jpg \
    images/background (8).jpg \
    images/background (8).jpg \
    images/background (9).jpg \
    images/background (9).jpg \
    images/background (9).jpg

RESOURCES += \
    build/Desktop_Qt_6_8_2_MinGW_64_bit-Release/release/qmake_qmake_qm_files.qrc
