#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <Qstring>
#include <QPushButton>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <QListWidgetItem>

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

enum PLAYMODE{
    ORDER_MODE,
    RANDOM_MODE,
    CIRCLE_MODE
};

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

public slots:
    /* 处理播放暂停 */
    void handlePlaySlot();
    /* 处理播放模式 */
    void handleModeSlot();
    /* 处理下一首 */
    void handleNextSlot();
    /* 处理上一首 */
    void handlePrevSlot();
    /* 处理音乐列表样式 */
    void handleListSlot();
    /* 处理背景切换 */
    void handleSkinSlot();
    /* 处理添加歌曲 */
    void handleAddSongSlot();

    /* 处理音乐进度 */
    void handlePositionSlot(int position);
    /* 处理音乐总时长 */
    void handleDurationSlot(int duration);
    /* 处理音乐进度条 */
    void handleSliderMoved(int position);
    /* 处理双击列表歌曲 */
    void handleItemDoubleClicked(QListWidgetItem *item);

    // 检查歌曲是否有重复
    bool isSongAlreadyAdded(const QString &songPath);
    // 删除重复的歌曲
    void removeDuplicateSong(const QString &songName);
    // 将歌曲地址保存到文本文件中
    void saveSongToFile(const QString &songPath);
    // 加载歌曲路径
    void loadSongsFromFile();
    // 删除songs.txt中的指定歌曲记录
    void removeSongFromFile(int index);

private:
    /* 设置按钮样式*/
    void setButtonStyle(QPushButton *button ,const QString &filename,int width,int high);
    /* 初始化按钮*/
    void initButtons();
    /* 设置背景 */
    void setBackGround(const QString &filename);
    /* 加载音乐文件夹 */
    void loadAppointMusicDir(const QString &filepath);
    /* 播放音乐 */
    void startPlayMusic();

    /* 记录已播放的歌曲索引 */
    QList<int> playedRows;
    /* 存储播放历史列表 */
    QList<int> historyList;
    /* 当前播放的歌曲的绝对路径 */
    QString currentSongPath;
    QString getSongPathByIndex(int index);

    /* 创建当前播放歌曲索引 */
    int currentSongIndex = -1;

    /* 显示动画 */
    void showAnimation(QWidget *window);
    /* 隐藏动画 */
    void hideAnimation(QWidget *window);

    /* 获取音乐时长 */
    QString formatTime(int milliseconds);

private:
    /* 音乐播放器 */
    QMediaPlayer *m_player;
    /* 当前播放模式 */
    PLAYMODE m_mode;
    /* 音乐绝对路径文件夹 */
    QString m_musicDir;
    /* 检测歌曲列表是否存在歌曲 */
    void loadAndPlayFirstSong();
    /* 列表存在状态 */
    bool m_isShowFlag;
    /* 标记是否在拖动进度条 */
    bool m_isDragging;

    Ui::MainWindow *ui;
};
#endif // MAINWINDOW_H
