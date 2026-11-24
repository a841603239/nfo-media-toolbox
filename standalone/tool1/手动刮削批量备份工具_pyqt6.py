import sys
import os
import shutil
from pathlib import Path
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QLineEdit, QPushButton, 
                             QTextEdit, QFileDialog, QProgressBar, QCheckBox,
                             QFrame, QGroupBox)
from PyQt6.QtCore import QThread, Qt, pyqtSignal

# ==========================================
# 后台工作线程（防止界面卡死）
# ==========================================
class BackupThread(QThread):
    # 定义信号，用于向主线程发送消息
    update_progress = pyqtSignal(int, int)  # 当前值, 总值
    log_message = pyqtSignal(str)            # 日志文本
    finished_signal = pyqtSignal()           # 完成信号

    def __init__(self, source_dir, target_dir, exclude_nfo=False, exclude_actor=False, export_tree=False):
        super().__init__()
        self.source_dir = source_dir
        self.target_dir = target_dir
        self.exclude_ext = {'.mp4', '.mkv'}
        if exclude_nfo:
            self.exclude_ext.add('.nfo')
        self.exclude_actor = exclude_actor
        self.export_tree = export_tree
        self._is_running = True

    def _filter_dirs(self, dirs):
        if self.exclude_actor:
            dirs[:] = [d for d in dirs if d != '.actors']

    def run(self):
        # 一次性收集所有需要备份的文件
        self.log_message.emit("正在扫描文件...")
        files_to_copy = []
        
        for root, dirs, files in os.walk(self.source_dir):
            self._filter_dirs(dirs)
            for file in files:
                file_ext = os.path.splitext(file)[1].lower()
                if file_ext not in self.exclude_ext:
                    files_to_copy.append((root, file))
        
        total_files = len(files_to_copy)
        
        if total_files == 0:
            self.log_message.emit("没有找到需要备份的文件。")
            self.finished_signal.emit()
            return

        self.log_message.emit(f"共发现 {total_files} 个文件，开始备份...")

        # 复制文件
        for i, (root, file) in enumerate(files_to_copy, 1):
            if not self._is_running: break
            
            copied_files = i
            self.update_progress.emit(copied_files, total_files)
            
            source_file = Path(root) / file
            rel_path = source_file.relative_to(self.source_dir)
            dest_path = Path(self.target_dir) / rel_path
            
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            
            try:
                shutil.copy2(source_file, dest_path)
            except OSError as e:
                self.log_message.emit(f"❌ 文件系统错误: {file} - {str(e)}")
            except PermissionError as e:
                self.log_message.emit(f"🔒 权限错误: {file} - {str(e)}")
            except Exception as e:
                self.log_message.emit(f"⚠️ 未知错误: {file} - {str(e)}")
        
        self.log_message.emit("备份完成！")
        
        if self.export_tree:
            self.export_directory_tree()
        
        self.finished_signal.emit()

    def export_directory_tree(self):
        self.log_message.emit("正在生成目录树...")
        tree_file_path = os.path.join(self.target_dir, "目录树.txt")
        
        try:
            with open(tree_file_path, 'w', encoding='utf-8') as f:
                f.write("目录结构\n" + "=" * 50 + "\n\n")
                
                for root, dirs, files in os.walk(self.target_dir):
                    self._filter_dirs(dirs)
                    
                    level = root.replace(self.target_dir, '').count(os.sep)
                    indent = ' ' * 2 * level
                    f.write(f"{indent}{os.path.basename(root)}/\n")
                    subindent = ' ' * 2 * (level + 1)
                    
                    for file in sorted(files):
                        if file != "目录树.txt":
                            f.write(f"{subindent}{file}\n")
            
            self.log_message.emit(f"目录树已导出到: {tree_file_path}")
        except Exception as e:
            self.log_message.emit(f"导出目录树失败: {str(e)}")

# ==========================================
# 主窗口界面
# ==========================================
class MainWindow(QMainWindow):
    # 样式常量
    STYLESHEET = """
        QMainWindow {
            background-color: #f5f5f5;
        }
        QWidget {
            font-family: "Microsoft YaHei", "Segoe UI", Arial, sans-serif;
            font-size: 11pt;
        }
        QLabel {
            color: #333333;
            font-weight: 500;
        }
        QLineEdit {
            padding: 8px 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            background-color: white;
            color: #333333;
            font-size: 11pt;
        }
        QLineEdit:focus {
            border-color: #2196F3;
        }
        QPushButton {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            background-color: #2196F3;
            color: white;
            font-weight: bold;
            font-size: 11pt;
        }
        QPushButton:hover {
            background-color: #1976D2;
        }
        QPushButton:disabled {
            background-color: #BDBDBD;
            color: #757575;
        }
        QCheckBox {
            spacing: 12px;
            color: #555555;
            font-size: 11pt;
            padding: 6px 0;
        }
        QCheckBox::indicator {
            width: 20px;
            height: 20px;
            border: 2px solid #BDBDBD;
            border-radius: 4px;
            background-color: white;
        }
        QCheckBox::indicator:checked {
            background-color: #4CAF50;
            border-color: #4CAF50;
        }
        QProgressBar {
            border: none;
            border-radius: 6px;
            background-color: #E0E0E0;
            text-align: center;
            height: 25px;
        }
        QProgressBar::chunk {
            background-color: #2196F3;
            border-radius: 6px;
        }
        QTextEdit {
            padding: 10px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            background-color: #FAFAFA;
            color: #333333;
            font-family: "Consolas", "Monaco", monospace;
            font-size: 10pt;
        }
        QGroupBox {
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            margin-top: 12px;
            padding-top: 10px;
            background-color: white;
            font-weight: bold;
            color: #333333;
        }
        QGroupBox::title {
            subcontrol-origin: margin;
            left: 15px;
            padding: 0 8px;
            background-color: white;
            color: #2196F3;
            font-weight: bold;
        }
        #option_group QCheckBox {
            padding: 8px 0;
        }
    """
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("手动刮削资源备份工具")
        self.resize(700, 600)
        
        self.apply_modern_style()
        
        # 核心部件
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        self.layout.setSpacing(15)
        self.layout.setContentsMargins(20, 20, 20, 20)
        
        # 初始化界面
        self.init_ui()
        
        # 工作线程引用
        self.worker = None

    def apply_modern_style(self):
        self.setStyleSheet(self.STYLESHEET)

    def _create_directory_row(self, label_text, input_field, btn, placeholder):
        h = QHBoxLayout()
        label = QLabel(label_text)
        label.setMinimumWidth(80)
        input_field.setPlaceholderText(placeholder)
        btn.setFixedWidth(80)
        h.addWidget(label)
        h.addWidget(input_field)
        h.addWidget(btn)
        return h

    def init_ui(self):
        title_label = QLabel("手动刮削资源备份工具")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title_label.setStyleSheet("font-size: 18pt; font-weight: bold; color: #2196F3;")
        self.layout.addWidget(title_label)
        
        line = QFrame()
        line.setFrameShape(QFrame.Shape.HLine)
        line.setFrameShadow(QFrame.Shadow.Sunken)
        line.setStyleSheet("background-color: #e0e0e0;")
        self.layout.addWidget(line)
        
        dir_group = QGroupBox("目录设置")
        dir_layout = QVBoxLayout()
        
        self.input_source = QLineEdit("")
        self.btn_source = QPushButton("浏览...", clicked=self.select_source)
        dir_layout.addLayout(self._create_directory_row("源目录：", self.input_source, self.btn_source, "选择要备份的源文件夹..."))
        
        self.input_target = QLineEdit("")
        self.btn_target = QPushButton("浏览...", clicked=self.select_target)
        dir_layout.addLayout(self._create_directory_row("目标目录：", self.input_target, self.btn_target, "选择备份保存的目标文件夹..."))
        
        dir_group.setLayout(dir_layout)
        self.layout.addWidget(dir_group)
        
        option_group = QGroupBox("备份选项")
        option_group.setObjectName("option_group")
        option_layout = QVBoxLayout()
        
        self.checkbox_exclude_nfo = QCheckBox("排除 .nfo 文件")
        self.checkbox_exclude_nfo.setChecked(True)
        option_layout.addWidget(self.checkbox_exclude_nfo)
        
        self.checkbox_exclude_actor = QCheckBox("排除 .actors 文件夹")
        self.checkbox_exclude_actor.setChecked(True)
        option_layout.addWidget(self.checkbox_exclude_actor)
        
        self.checkbox_export_tree = QCheckBox("备份完成后导出目录树")
        self.checkbox_export_tree.setChecked(True)
        option_layout.addWidget(self.checkbox_export_tree)
        
        option_group.setLayout(option_layout)
        self.layout.addWidget(option_group)

        self.progress_bar = QProgressBar()
        self.progress_bar.setTextVisible(True)
        self.progress_bar.setFormat("%p%")
        self.layout.addWidget(self.progress_bar)

        log_group = QGroupBox("操作日志")
        log_layout = QVBoxLayout()
        self.log_area = QTextEdit()
        self.log_area.setReadOnly(True)
        self.log_area.setMinimumHeight(150)
        self.log_area.setPlaceholderText("日志信息将显示在这里...")
        log_layout.addWidget(self.log_area)
        log_group.setLayout(log_layout)
        self.layout.addWidget(log_group)

        h3 = QHBoxLayout()
        self.btn_start = QPushButton("开始备份", clicked=self.start_backup)
        self.btn_start.setFixedHeight(45)
        self.btn_start.setFixedWidth(200)
        self.btn_start.setStyleSheet("""
            QPushButton {
                background-color: #4CAF50;
                font-size: 12pt;
                padding: 12px 24px;
            }
            QPushButton:hover {
                background-color: #43A047;
            }
        """)
        h3.addStretch()
        h3.addWidget(self.btn_start)
        h3.addStretch()
        self.layout.addLayout(h3)

    def _select_directory(self, input_field, title):
        dir_path = QFileDialog.getExistingDirectory(self, title)
        if dir_path:
            input_field.setText(dir_path)

    def select_source(self):
        self._select_directory(self.input_source, "选择源文件夹")

    def select_target(self):
        self._select_directory(self.input_target, "选择目标文件夹")

    def start_backup(self):
        source = self.input_source.text()
        target = self.input_target.text()

        if not source or not target:
            self.log_area.append("错误：请先设置源目录和目标目录")
            return

        self.btn_start.setEnabled(False)
        self.btn_start.setText("备份中...")
        self.log_area.clear()
        self.log_area.append("任务已启动...")

        exclude_nfo = self.checkbox_exclude_nfo.isChecked()
        exclude_actor = self.checkbox_exclude_actor.isChecked()
        export_tree = self.checkbox_export_tree.isChecked()
        self.worker = BackupThread(source, target, exclude_nfo, exclude_actor, export_tree)
        
        self.worker.update_progress.connect(lambda c, t: (self.progress_bar.setMaximum(t), self.progress_bar.setValue(c)))
        self.worker.log_message.connect(self.log_area.append)
        self.worker.finished_signal.connect(self.on_finished)
        self.worker.start()

    def on_finished(self):
        self.btn_start.setEnabled(True)
        self.btn_start.setText("开始备份")
        self.log_area.append("任务结束。")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
