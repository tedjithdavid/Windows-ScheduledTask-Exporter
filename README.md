# Windows-ScheduledTask-Exporter
PowerShell script to export Windows scheduled tasks to CSV with comprehensive details and filtering

A comprehensive PowerShell script that exports Windows scheduled tasks to CSV format with detailed information including security settings, execution history, and trigger details. Perfect for system administrators managing multiple Windows servers.

**🔧 Requirements**

PowerShell 5.1 or higher
Windows Server 2012 R2 or higher (or Windows 10/11)
Administrative privileges on the target server

**📂 Output**

The script generates:
Local file: C:\Temp\<ServerName>-Task-YYYYMMDD-HHMMSS.csv

**🔍 Filtering**

The script automatically excludes:

**Folder-based exclusions:**

Tasks in folders starting with Microsoft\

**Task name exclusions:**

MicrosoftEdgeUpdate*
SensorFramework*
User_Feed_Synchronization*
CheckAutoServices*
Configuration Manager Health Evaluation*
CreateExplorerShellUnelevatedTask*


**Add Custom Filters**

powershell# Add to the $ExcludedTaskPrefixes array:
$ExcludedTaskPrefixes = @(
    "YourCustomPrefix",
    "AnotherPrefix"
)


**Change Output Location**

powershell# Modify the output path:
$OutputPath = "D:\Reports"


**🤝 Contributing**

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

**Fork the repository**

Create a feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request

**📄 License**

This project is licensed under the MIT License - see the LICENSE file for details.


**🙏 Acknowledgments**

Microsoft PowerShell team for the ScheduledTasks module
Windows Task Scheduler for providing comprehensive task management APIs
The PowerShell community for best practices and inspiration
