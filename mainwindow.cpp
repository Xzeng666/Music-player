#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QIcon>

/* 文件系统 */
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QFileDialog>

/* 图片类 */
#include <QPixmap>
#include <QPalette>

/* 消息对话框 */
#include <QMessageBox>

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QPropertyAnimation>
#include <QListWidgetItem>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent),
    m_mode(ORDER_MODE),
    m_isShowFlag(false),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    setWindowTitle("MusicPlayer");

    // 初始化音频播放器
    m_player = new QMediaPlayer(this);
    QAudioOutput *audioOutput = new QAudioOutput(this);  // 创建音频输出
    m_player->setAudioOutput(audioOutput);  // 将播放器与音频输出绑定

    // 设置默认背景
    setBackGround("images/background (3).jpg");
    setFixedSize(1080, 720);

    // 初始化按钮
    initButtons();

    // 读取保存的歌曲列表
    loadSongsFromFile();

    // 默认加载第一首音乐
    ui->musicList->setCurrentRow(1);  // 默认选择第一首歌曲
    startPlayMusic();
    handlePlaySlot();

}

/* 设置背景 */
void MainWindow::setBackGround(const QString &filename){
    if (!QFile::exists(filename)) {
        qDebug() << "背景图文件不存在：" << filename;
        return;
    }

    // 创建QPixmap对象并加载图片
    QPixmap pixmap(filename);

    // 获取当前窗口大小
    QSize windowSize = this->size();

    // 将图片缩放到当前窗口大小
    QPixmap scaledPixmap = pixmap.scaled(windowSize, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);

    // 创建 QPalette 对象并设置背景调色板
    QPalette palette = this->palette();
    palette.setBrush(QPalette::Window, QBrush(scaledPixmap));

    // 将调色板应用到窗口上
    this->setPalette(palette);
}

/* 设置按钮样式*/
void MainWindow::setButtonStyle(QPushButton *button ,const QString &filename,int width,int high){
    /* 设置按钮大小 */
    button->setFixedSize(width,high);
    /* 设置按钮图标 */
    button->setIcon(QIcon(filename));
    /* 设置图标大小 */
    button->setIconSize(QSize(button->width(),button->height()));
    /* 设置按钮背景*/
    button->setStyleSheet("background-color:transparent");
    // /* 判断按钮图标文件是否存在 */
    // if (!QFile::exists(filename)) {
    //     qDebug() << "文件不存在：" << filename;
    //     return;
    // }
}

/* 初始化按钮*/
void MainWindow::initButtons(){
    /* 背景换肤 */
    setButtonStyle(ui->skinBtn,"Icon/skin.png",30,30);
    /* 添加歌曲 */
    setButtonStyle(ui->addBtn,"Icon/add.png",30,30);
    /* 调节音量 */
    setButtonStyle(ui->volBtn,"Icon/volume.png",0,0);
    /* 上一首 */
    setButtonStyle(ui->prevBtn,"Icon/prev.png",50,50);
    /* 播放/暂停 */
    setButtonStyle(ui->playBtn,"Icon/play.png",50,50);
    /* 下一首 */
    setButtonStyle(ui->nextBtn,"Icon/next.png",50,50);
    /* 播放顺序 */
    setButtonStyle(ui->modeBtn,"Icon/order.png",50,50);
    /* 歌曲列表 */
    setButtonStyle(ui->listBtn,"Icon/list.png",50,50);
    ui->musicList->setStyleSheet("QListWidget{"
                                 "border:none;"
                                 "border-radius:20px;"
                                 "background-color:rgba(255,255,255,0.6);}");
    /* 初始化隐藏列表 */
    ui->musicList->hide();


    /* 按钮信号和槽 */
    // 添加歌曲功能
    connect(ui->addBtn, &QPushButton::clicked, this, &MainWindow::handleAddSongSlot);
    // 调节音量

    //判断播放按钮事件状态
    connect(ui->playBtn,&QPushButton::clicked,this,&MainWindow::handlePlaySlot);
    // 判断播放模式
    connect(ui->modeBtn,&QPushButton::clicked,this,&MainWindow::handleModeSlot);
    // 下一首
    connect(ui->nextBtn,&QPushButton::clicked,this,&MainWindow::handleNextSlot);
    // 上一首
    connect(ui->prevBtn,&QPushButton::clicked,this,&MainWindow::handlePrevSlot);
    // 音乐列表
    connect(ui->listBtn,&QPushButton::clicked,this,&MainWindow::handleListSlot);
    // 处理背景切换
    connect(ui->skinBtn, &QPushButton::clicked, this, &MainWindow::handleSkinSlot);
    // 处理音乐位置变化
    connect(m_player, &QMediaPlayer::positionChanged, this, &MainWindow::handlePositionSlot);
    // 处理音乐总时长
    connect(m_player, &QMediaPlayer::durationChanged, this, &MainWindow::handleDurationSlot);
    // 处理双击音乐列表
    connect(ui->musicList, &QListWidget::itemDoubleClicked, this, &MainWindow::handleItemDoubleClicked);

    /* 处理进度条拖动，跳转到指定位置 */
    // 当开始拖动时，标记为正在拖动
    connect(ui->progressBar, &QSlider::sliderPressed, this, [=]() {
        m_isDragging = true;
    });
    // 当停止拖动时，更新进度并标记为不再拖动
    connect(ui->progressBar, &QSlider::sliderReleased, this, [=]() {
        m_isDragging = false;
        int position = ui->progressBar->value();
        handleSliderMoved(position);
    });

}

/* 处理添加歌曲 */
void MainWindow::handleAddSongSlot() {
    // 弹出文件选择对话框，允许用户选择音乐文件
    QString fileName = QFileDialog::getOpenFileName(this, "选择歌曲", "", "MP3 Files (*.mp3);;All Files (*)");

    if (fileName.isEmpty()) {
        return;  // 如果没有选择文件，返回
    }

    // 检查文件是否存在
    if (!QFile::exists(fileName)) {
        QMessageBox::warning(this, "错误", "歌曲文件不存在！");
        return;
    }

    // 获取歌曲的文件名，不包含后缀名
    QString songName = QFileInfo(fileName).baseName();  // 使用 baseName() 来去掉扩展名
    QString songPath = fileName;  // 使用绝对路径

    // 检查该歌曲是否已经添加
    if (isSongAlreadyAdded(songPath)) {
        QMessageBox::information(this, "提示", "该歌曲已在歌单中！");
        return;
    }

    // 删除重复的歌曲（如果存在的话）
    removeDuplicateSong(songName);

    // 将歌曲路径保存到 .txt 文件
    saveSongToFile(songPath);

    // 将歌曲添加到音乐列表中，跳过“歌曲列表”这一行
    ui->musicList->addItem(songName);
}

/* 删除重复的歌曲 */
void MainWindow::removeDuplicateSong(const QString &songName) {
    int rowCount = ui->musicList->count();

    // 遍历音乐列表，检查是否存在相同歌曲名的项
    for (int i = 0; i < rowCount; ++i) {
        QListWidgetItem *item = ui->musicList->item(i);
        if (item->text() == songName) {
            // 如果找到重复歌曲，删除它
            ui->musicList->takeItem(i);
            break;  // 只删除第一次出现的重复项
        }
    }
}

/* 检查歌曲是否有重复 */
bool MainWindow::isSongAlreadyAdded(const QString &songPath) {
    QFile file("songs.txt");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line == songPath) {  // 如果文件中存在该路径，则返回 true
                return true;
            }
        }
    }
    return false;  // 如果没有找到重复歌曲，返回 false
}

/* 将歌曲地址保存到文本文件中 */
void MainWindow::saveSongToFile(const QString &songPath) {
    QFile file("songs.txt");
    if (file.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out << songPath << "\n";  // 保存绝对路径
    }
}

/* 加载歌曲路径 */
void MainWindow::loadSongsFromFile() {
    QFile file("songs.txt");

    // 如果文件不存在，创建并写入初始内容
    if (!file.exists()) {
        QFile newFile("songs.txt");
        if (newFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&newFile);
            out << "\n";  // 写入空行
        }
    }

    // 读取文件内容并将歌曲路径添加到列表
    if (file.open(QIODevice::ReadWrite | QIODevice::Text)) {  // 使用 ReadWrite 模式
        QTextStream in(&file);
        QStringList lines;

        while (!in.atEnd()) {
            lines.append(in.readLine());  // 读取每一行并保存到列表中
        }

        // 检查第一行是否为空行，如果不是，则在顶部添加一个空行
        if (!lines.isEmpty() && !lines.first().isEmpty()) {
            lines.prepend("");  // 将一个空行插入到列表的顶部
        }

        // 清空现有列表并重新写入歌曲列表
        ui->musicList->clear();  // 清空现有的列表
        ui->musicList->addItem("歌曲列表");  // 顶部添加"歌曲列表"
        ui->musicList->item(0)->setTextAlignment(Qt::AlignCenter);  // 设置文本居中

        // 写入新的内容（包括空行）
        file.resize(0);  // 清空文件内容
        QTextStream out(&file);
        for (const QString &line : lines) {
            out << line << "\n";  // 写入每一行
        }

        // 将歌曲路径添加到列表
        for (int i = 1; i < lines.size(); ++i) {  // 从第 1 行开始（跳过"歌曲列表"）
            QString songPath = lines[i];  // 获取歌曲路径
            QString songName = QFileInfo(songPath).baseName();  // 获取文件名
            if (!songName.isEmpty()) {
                ui->musicList->addItem(songName);  // 将歌曲添加到音乐列表
            }
        }
    }
}

/* 检测歌曲列表是否存在歌曲 */
void MainWindow::loadAndPlayFirstSong() {
    int row = ui->musicList->currentRow();

    // 确保点击的是第一个有效的歌曲行（跳过"歌曲列表"）
    if (row > 0) {
        QString songPath = getSongPathByIndex(row);  // 获取绝对路径
    }
}

// 删除songs.txt中的指定歌曲记录
void MainWindow::removeSongFromFile(int index) {
    QFile file("songs.txt");
    if (!file.open(QIODevice::ReadWrite | QIODevice::Text)) {
        QMessageBox::warning(this, "错误", "无法打开歌曲列表文件！");
        return;
    }

    QTextStream in(&file);
    QStringList lines;
    while (!in.atEnd()) {
        lines.append(in.readLine());  // 读取所有行
    }
    file.close();

    // 从列表中删除歌曲记录
    if (index >= 1 && index < lines.size()) {
        lines.removeAt(index);  // 删除对应行（跳过"歌曲列表"行，假设其是第0行）
    }

    // 重新写入文件，覆盖原文件
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        for (const QString &line : lines) {
            out << line << "\n";
        }
    }
}

/* 处理背景切换 */
void MainWindow::handleSkinSlot() {
    // 弹出文件选择对话框
    QString fileName = QFileDialog::getOpenFileName(this, "选择背景图片", "", "Images (*.png *.jpg *.jpeg *.bmp)");

    // 如果没有选择文件，则返回
    if (fileName.isEmpty()) {
        return;
    }

    // 调用 setBackGround 来更换背景
    setBackGround(fileName);
}

/* 处理双击音乐列表 */
void MainWindow::handleItemDoubleClicked(QListWidgetItem *item) {
    int row = ui->musicList->row(item);  // 获取双击的项的行号

    // 第0行（标题行）不做反应
    if (row == 0) return;

    // 获取选中的歌曲名称
    QString songName = item->text();

    // 查找 `.txt` 文件中对应的绝对路径
    QString songPath = getSongPathByIndex(row);
    if (!songPath.isEmpty()) {
        // 更新播放/暂停按钮状态
        handlePlaySlot();

        m_player->setSource(QUrl::fromLocalFile(songPath));
        ui->musicList->setCurrentRow(row); // 高亮显示当前行
        startPlayMusic(); // 播放歌曲
    }
    // 更新暂停/播放按钮状态
    handlePlaySlot();
}

/* 处理进度条拖动 */
void MainWindow::handleSliderMoved(int position) {
    // 设置播放器跳转到指定位置
    m_player->setPosition(position);

    // 更新当前时间显示
    ui->currentTime->setText(formatTime(position));
}

/* 获取音乐时间 */
QString MainWindow::formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000) % 60;  // 获取秒
    int minutes = (milliseconds / 60000) % 60; // 获取分钟
    return QString("%1:%2").arg(minutes, 2, 10, QChar('0')).arg(seconds, 2, 10, QChar('0'));
}

/* 处理音乐总时长 */
void MainWindow::handleDurationSlot(int duration) {
    // 设置进度条范围
    ui->progressBar->setRange(0, duration);
    // 更新总时长显示
    ui->totalTime->setText(formatTime(duration));
}

/* 处理音乐进度 */
void MainWindow::handlePositionSlot(int position) {
    // 未处于拖动进度条状态，则实时更新进度条
    if (!m_isDragging) {
        ui->progressBar->setValue(position);    // 更新当前时间显示
        ui->currentTime->setText(formatTime(position)); // 更新进度条
    }
}

/* 显示动画 */
void MainWindow::showAnimation(QWidget *window){
    QPropertyAnimation animation(window,"pos");
    // 动画持续时间
    animation.setDuration(300);
    // 起始坐标
    animation.setStartValue(QPoint(this->width(),0));
    // 结束坐标
    animation.setEndValue(QPoint(this->width()-ui->musicList->width(),0));
    animation.start();
    QEventLoop loop;
    // 等待动画结束
    connect(&animation,&QPropertyAnimation::finished,&loop,&QEventLoop::quit);
    loop.exec();
}

/* 隐藏动画 */
void MainWindow::hideAnimation(QWidget *window){
    QPropertyAnimation animation(window,"pos");
    // 动画持续时间
    animation.setDuration(300);
    // 起始坐标
    animation.setStartValue(QPoint(this->width() - ui->musicList->width(),0));
    // 结束坐标
    animation.setEndValue(QPoint(this->width(),0));
    animation.start();
    QEventLoop loop;
    // 等待动画结束
    connect(&animation,&QPropertyAnimation::finished,&loop,&QEventLoop::quit);
    loop.exec();
}

/* 处理音乐列表样式 */
void MainWindow::handleListSlot(){
    if(m_isShowFlag == false){
        ui->musicList->show();
        showAnimation(ui->musicList); // 调用渐入动画显示
        m_isShowFlag = true; // 更新状态
    }
    else{
        hideAnimation(ui->musicList); // 调用渐出动画隐藏
        ui->musicList->hide();
        m_isShowFlag = false;
    }
}

/* 播放音乐 */
void MainWindow::startPlayMusic() {
    int currentRow = ui->musicList->currentRow();
    qDebug() << "currentRow: " << currentRow;

    // 确保当前选择的是有效的歌曲（跳过"歌曲列表"）
    if (ui->musicList->count() <= 1) {
        return;  // 如果没有歌曲或选择的是“歌曲列表”，不进行任何操作
    }

    QString songPath = getSongPathByIndex(currentRow);  // 获取当前歌曲的绝对路径
    qDebug() << "Playing song from path: " << songPath;

    if (!songPath.isEmpty()) {
        if (QFile::exists(songPath)) {
            m_player->setSource(QUrl::fromLocalFile(songPath));  // 设置播放源
            m_player->play();  // 播放歌曲
        } else {
            // 保存当前歌曲的索引
            int previousRow = ui->musicList->currentRow();
            bool isPlaying = m_player->playbackState() == QMediaPlayer::PlayingState;
            // 如果歌曲文件不存在，提示用户并给出删除或取消的选项
            QMessageBox msgBox;
            msgBox.setIcon(QMessageBox::Warning);
            msgBox.setWindowTitle("错误");
            msgBox.setText("歌曲文件不存在！");
            msgBox.setInformativeText("是否删除该歌曲记录？");
            msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::Cancel);
            msgBox.setDefaultButton(QMessageBox::Cancel);

            // 设置按钮提示
            msgBox.button(QMessageBox::Yes)->setText("确认");
            msgBox.button(QMessageBox::Cancel)->setText("取消");

            int ret = msgBox.exec();

            // 如果用户选择了删除
            if (ret == QMessageBox::Yes) {
                // 删除该歌曲记录
                removeSongFromFile(currentRow);
                ui->musicList->takeItem(currentRow);  // 从列表中删除该项
            }

            // 恢复歌曲状态
            ui->musicList->setCurrentRow(previousRow);  // 恢复到之前的歌曲
            if (isPlaying) {
                m_player->play();  // 如果之前在播放，继续播放
            } else {
                m_player->pause();  // 如果之前是暂停状态，则暂停
            }
        }
    }
}

/* 处理上一首 */
void MainWindow::handlePrevSlot() {
    int totalSongs = ui->musicList->count();

    if (totalSongs == 0) return;

    int currentRow = ui->musicList->currentRow();
    int prevRow = currentRow;

    // 顺序播放
    if (m_mode == ORDER_MODE) {
        prevRow = (currentRow - 1 + totalSongs) % totalSongs;
        if (prevRow == 0) prevRow = totalSongs - 1;  // 修改为 totalSongs - 1
    }
    // 随机播放
    else if (m_mode == RANDOM_MODE) {
        QList<int> candidates;

        // 排除当前歌曲和已播放歌曲
        for (int i = 1; i < totalSongs; ++i) {  // 从第 1 行开始
            if (i != currentRow && !playedRows.contains(i)) {
                candidates.append(i);
            }
        }

        if (!candidates.isEmpty()) {
            // 从候选列表中随机选择
            prevRow = candidates.at(rand() % candidates.size());
        } else {
            // 所有歌曲已播放过，重置播放记录并从头播放
            playedRows.clear();
            handleNextSlot();  // 跳转到下一首
            return;
        }
    }
    // 单曲循环
    else if (m_mode == CIRCLE_MODE) {
        prevRow = currentRow;  // 单曲循环不改变当前歌曲
    }

    // 获取上一首歌曲的绝对路径
    QString prevSongPath = getSongPathByIndex(prevRow);

    // 播放上一首歌曲
    m_player->setSource(QUrl::fromLocalFile(prevSongPath));  // 设置播放源
    // 更新当前行
    ui->musicList->setCurrentRow(prevRow);
    // 播放歌曲
    startPlayMusic();
    // 更新播放/暂停状态图标
    handlePlaySlot();
}

/* 处理下一首 */
void MainWindow::handleNextSlot() {
    int totalSongs = ui->musicList->count();

    if (totalSongs == 0) return;

    int currentRow = ui->musicList->currentRow();
    int nextRow = currentRow;

    // 顺序播放
    if (m_mode == ORDER_MODE) {
        nextRow = (currentRow + 1) % totalSongs;
        if (nextRow == 0) nextRow = 1;  // 如果是返回标题行，跳到第一首歌曲
    }
    // 随机播放
    else if (m_mode == RANDOM_MODE) {
        QList<int> candidates;
        // 从第1行开始遍历，排除标题行和当前歌曲
        for (int i = 1; i < totalSongs; ++i) {
            if (i != currentRow && !playedRows.contains(i)) {
                candidates.append(i);
            }
        }
        if (!candidates.isEmpty()) {
            // 从候选列表中随机选择
            nextRow = candidates.at(rand() % candidates.size());
        } else {
            // 所有歌曲已播放过，重置播放记录并从头播放
            playedRows.clear();
            handleNextSlot();  // 跳转到下一首
            return;
        }
    }
    // 单曲循环
    else if (m_mode == CIRCLE_MODE) {
        nextRow = currentRow;  // 单曲循环不改变当前歌曲
    }

    // 获取下一首歌曲的绝对路径
    QString nextSongPath = getSongPathByIndex(nextRow);

    // 播放下一首歌曲
    m_player->setSource(QUrl::fromLocalFile(nextSongPath));  // 设置播放源
    // 更新当前行
    ui->musicList->setCurrentRow(nextRow);
    // 播放歌曲
    startPlayMusic();
    // 更新播放/暂停状态图标
    handlePlaySlot();
}

/* 获取指定索引的歌曲路径 */
QString MainWindow::getSongPathByIndex(int index) {
    QFile file("songs.txt");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        int currentIndex = 0;
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (currentIndex == index) {  // index 与文本文件行号直接对应
                file.close();
                return line;
            }
            ++currentIndex;
        }
        file.close();
    }
    return "";
}

/* 处理播放模式 */
void MainWindow::handleModeSlot(){
    // 当前播放模式为顺序播放
    if(m_mode == ORDER_MODE){
        // 状态更改为随机播放
        m_mode = RANDOM_MODE;
        playedRows.clear(); // 进入随机模式时清空播放记录
        ui->modeBtn->setIcon(QIcon("Icon/random.png"));
    }
    // 当前播放模式为随机播放
    else if(m_mode == RANDOM_MODE){
        // 状态更改为单曲循环
        m_mode = CIRCLE_MODE;
        ui->modeBtn->setIcon(QIcon("Icon/loop.png"));
    }
    // 当前播放模式为单曲循环
    else if(m_mode == CIRCLE_MODE){
        // 状态更改为顺序播放
        m_mode = ORDER_MODE;
        ui->modeBtn->setIcon(QIcon("Icon/order.png"));
    }
}

/* 处理播放暂停 */
void MainWindow::handlePlaySlot() {
    // 如果当前状态是播放状态，暂停播放
    if (m_player->playbackState() == QMediaPlayer::PlayingState) {
        m_player->pause();
        ui->playBtn->setIcon(QIcon("Icon/play.png"));  // 设置为播放图标
    }
    // 如果当前状态是暂停状态，继续播放
    else{
        ui->playBtn->setIcon(QIcon("Icon/stop.png"));  // 设置为暂停图标
        m_player->play();
    }
}

MainWindow::~MainWindow()
{
    delete ui;
}
