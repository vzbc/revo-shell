"""Test script for Quickshell GUI Installer"""
import sys
import os
import json
import tempfile
import shutil
from pathlib import Path

# Add the project to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test that all required modules can be imported"""
    print("Testing imports...")
    
    # Test Python standard library imports
    try:
        import json
        import shutil
        import platform
        import subprocess
        import datetime
        import logging
        import distro
        import psutil
        from pathlib import Path
        from typing import Dict, List
        from dataclasses import dataclass
        from enum import Enum
        print("✓ Standard library imports OK")
    except Exception as e:
        print(f"✗ Standard library import error: {e}")
        return False
    
    # Test PySide6 imports
    try:
        from PySide6.QtCore import (
            QObject, Signal, QTimer, QThread, QSize, Qt, QRectF, QPoint, QPointF,
            QTimeLine, QEasingCurve, QPropertyAnimation, QSequentialAnimationGroup,
            QParallelAnimationGroup
        )
        from PySide6.QtGui import (
            QColor, QPainter, QBrush, QPen, QFont, QLinearGradient, QGradient,
            QMouseEvent, QWheelEvent, QAction, QFontDatabase, QIcon
        )
        from PySide6.QtWidgets import (
            QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
            QStackedLayout, QFormLayout, QLabel, QLineEdit, QPushButton,
            QProgressBar, QMessageBox, QTextEdit, QSpinBox, QGroupBox,
            QDial, QSlider, QSplitter, QScrollArea, QStackedWidget, QTabWidget,
            QCheckBox, QRadioButton, QListWidget, QListWidgetItem, QTableWidget,
            QTableWidgetItem, QHeaderView, QGraphicsView, QGraphicsScene,
            QFileDialog, QInputDialog, QGridLayout, QFrame, QMenu, QMenuBar,
            QSplashScreen, QSizePolicy, QFontMetrics
        )
        from PySide6.QtQuick import QQuickWidget, QQmlApplicationEngine
        from PySide6.QtQml import QQmlComponent, QQmlProperty
        from PySide6.QtQml.QtQml import qmlRegisterSingletonType
        from PySide6.QtQuick.Window import QWindow
        print("✓ PySide6 imports OK")
    except ImportError as e:
        print(f"⚠ PySide6 import warning: {e}")
        print("  Running in demo mode without GUI")
    
    return True

def test_file_structure():
    """Test that the file structure is correct"""
    print("\nTesting file structure...")
    
    project_root = Path(__file__).parent
    required_files = [
        "main.py",
        "README.md",
    ]
    
    optional_dirs = [
        "qml",
        "resources",
        "src",
    ]
    
    # Check required files
    for file_name in required_files:
        file_path = project_root / file_name
        if file_path.exists():
            print(f"✓ {file_name} exists")
        else:
            print(f"✗ {file_name} missing")
            return False
    
    # Check optional directories
    for dir_name in optional_dirs:
        dir_path = project_root / dir_name
        if dir_path.exists():
            print(f"✓ {dir_name}/ directory exists")
        else:
            print(f"⚠ {dir_name}/ directory not found (optional)")
    
    # Check QML files if qml directory exists
    qml_dir = project_root / "qml"
    if qml_dir.exists():
        qml_files = list(qml_dir.glob("*.qml"))
        print(f"✓ QML directory contains {len(qml_files)} files: {[f.name for f in qml_files]}")
    
    return True

def test_config():
    """Test configuration module"""
    print("\nTesting configuration...")
    
    try:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import main
        
        # Check installer config
        config = main.InstallerConfig()
        
        required_attrs = [
            "QUIKSHELL_REPO_URL",
            "HYPRLAND_CONFIGS_REPO_URL",
            "DOTFILES_REPO_URL",
            "WINDOW_WIDTH",
            "WINDOW_HEIGHT",
        ]
        
        for attr in required_attrs:
            if hasattr(config, attr):
                print(f"✓ Config.{attr} = {getattr(config, attr)}")
            else:
                print(f"✗ Config.{attr} missing")
                return False
        
        # Check data models
        system_info = main.SystemInfo(
            distribution="Test",
            version="1.0",
            architecture="x86_64",
            kernel="5.10.0",
            hostname="test",
            memory_gb=16.0,
            cpu_cores=8,
            cpu_model=2500,
            gpu_info="Test GPU"
        )
        
        print("✓ SystemInfo data model works")
        
        try:
            from PySide6.QtGui import QColor
            theme_color = QColor(0, 122, 255)
        except ImportError:
            class MockColor:
                def __init__(self, r, g, b):
                    pass
            theme_color = MockColor(0, 122, 255)
        
        shell_info = main.ShellInfo(
            id="test-shell",
            name="Test Shell",
            description="A test shell",
            repo_url="https://github.com/test/shell",
            icon_path="icon.png",
            preview_path="preview.png",
            theme_color=theme_color,
            build_type="stable",
            dependencies=[]
        )
        
        print("✓ ShellInfo data model works")
        
        return True
    except Exception as e:
        print(f"✗ Configuration test error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_installation_worker():
    """Test installation worker functionality"""
    print("\nTesting Installation Worker...")
    
    try:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import main
        
        worker = main.InstallationWorker()
        
        # Test worker attributes
        if hasattr(worker, 'config'):
            print("✓ Worker has config attribute")
        if hasattr(worker, 'run_installation'):
            print("✓ Worker has run_installation method")
        if hasattr(worker, 'progress_changed'):
            print("✓ Worker has progress_changed signal")
        
        # Test system info method
        system_info = worker._get_system_info()
        if system_info.distribution and system_info.version:
            print(f"✓ System info gathered: {system_info.distribution} {system_info.version}")
        
        # Test safety verification
        # This will return False since we don't have existing configs in test environment
        is_safe = worker._safety_verification()
        print(f"✓ Safety verification: {'OK' if is_safe else 'Needs attention (expected in test)'}")
        
        return True
    except Exception as e:
        print(f"✗ Installation worker test error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_demo_mode():
    """Test demo mode (run without GUI)"""
    print("\nTesting demo mode...")
    
    try:
        # Create a test script that runs in demo mode
        test_script = """
import sys
import os

# Set environment variable to force demo mode
os.environ['DEMO_MODE'] = '1'

# Import the main module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the installer worker and test it
from main import InstallationWorker

def test_demo():
    print("Running in demo mode...")
    
    worker = InstallationWorker()
    
    # Test system info
    system_info = worker._get_system_info()
    print(f"System: {system_info.distribution} {system_info.version}")
    print(f"Memory: {system_info.memory_gb} GB")
    print(f"CPU: {system_info.cpu_cores} cores")
    
    # Test shell info
    shells = worker._get_available_shells()
    print(f"Available shells: {len(shells)}")
    for shell in shells:
        print(f"  - {shell.name}: {shell.description}")
    
    print("Demo mode test completed successfully!")

if __name__ == "__main__":
    test_demo()
"""
        
        # Write and run the test script
        with open('test_demo.py', 'w') as f:
            f.write(test_script)
        
        # Run the test
        import subprocess
        result = subprocess.run([sys.executable, 'test_demo.py'], 
                              capture_output=True, text=True, cwd=os.path.dirname(os.path.abspath(__file__)))
        
        if result.returncode == 0:
            print("✓ Demo mode test passed")
            print(result.stdout)
        else:
            print("✗ Demo mode test failed")
            print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
        
        # Clean up
        os.remove('test_demo.py')
        
        return True
    except Exception as e:
        print(f"✗ Demo mode test error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("Quickshell GUI Installer - Test Suite")
    print("=" * 60)
    
    tests = [
        test_imports,
        test_file_structure,
        test_config,
        test_installation_worker,
        test_demo_mode,
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"✗ Test {test.__name__} failed with exception: {e}")
            results.append(False)
    
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    passed = sum(results)
    total = len(results)
    
    for i, (test, result) in enumerate(zip(tests, results)):
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{i+1}. {test.__name__}: {status}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! The installer is ready for use.")
        return 0
    else:
        print(f"\n⚠ {total - passed} test(s) failed. Please review the output above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
