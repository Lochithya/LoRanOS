# LoRanOS - Hardware Information Display Operating System

LoRanOS is a simple, custom-built 16-bit operating system kernel written in Assembly language. It is designed specifically to **query and display hardware-level information** in a
virtualized environment using **Oracle VirtualBox**, **Ubuntu Linux**, and **NASM** (Netwide Assembler). Inspired by low-level system programming and OS development projects like 
MikeOS , LoRanOS demonstrates direct interaction with system hardware using BIOS interrupts and CPU instruction sets.

## 🎯 Objective

The goal of LoRanOS is to **retrieve and display detailed hardware information** of a virtualized x86 machine environment. This project showcases key concepts of OS kernel development, 
BIOS-level programming, and CPU feature querying.

---

## ⚙️ Features Displayed

LoRanOS is capable of detecting and displaying the following hardware components and specifications:

| Component               | Description                                     |
|-------------------------|-------------------------------------------------|
| Base Memory             | Amount of base (conventional) RAM               |
| Extended Memory (1M-16M)| RAM available between 1MB and 16MB              |
| Extended Memory (>16M)  | RAM available above 16MB                        |
| Aggregate RAM           | Total available RAM                             |
| CPU Vendor              | Processor manufacturer (e.g., GenuineIntel)     |
| CPU Descriptor          | Processor name/descriptor                       |
| CPU Flags               | CPU feature flags (e.g., FPU, MMX, SSE)         |
| HDD Count               | Number of attached hard disk drives             |
| Mouse Availability      | Mouse hardware detection                        |
| Serial Ports            | Number of serial ports detected                 |
| Serial Port Address     | Base I/O address of Serial Port 1               |
| Graphics Adapter        | VGA compatibility of video adapter              |
| USB Controller          | Emulated USB controller status                  |
| Virtualization          | VirtualBox virtualization platform              |
| BIOS Version            | BIOS info (not detected/emulated)              |
| Audio Device            | Emulated sound device type                      |
| Network Adapter         | Type of network card emulated                   |
| Battery Status          | Presence/absence of a battery (expected: none)  |

---

## 🛠️ Technologies Used

- **Assembly Language (NASM)** – for kernel-level development  
- **MikeOS** – as reference for low-level BIOS interaction  
- **Oracle VirtualBox** – for testing the OS in a virtual environment  
- **Ubuntu Linux** – development host system  
- **QEMU** (optional) – for alternative emulation and testing

---

### 🆚 Dual Boot vs Virtual Machine: Which One for LoRanOS?

| Feature/Aspect              | Dual Boot                             | Virtual Machine (Oracle VM)             |
|----------------------------|----------------------------------------|------------------------------------------|
| **System Reboot Required** |  Yes (every switch)                    |  No (runs inside host OS)              |
| **Setup Complexity**       |  High (partitioning, bootloader)       |  Easy (VM creation is straightforward) |
| **Testing Speed**          |  Slow (full reboot needed)             |  Fast (instant reloads)                |
| **Hardware Access**        |  Direct/native                         |  Virtualized (good for most use cases) |
| **Risk of Data Loss**      |  High (modifying boot configs)         |  Very low                              |
| **Snapshot/Backup Support**|  No                                    |  Yes (easy to save/restore states)     |
| **Performance**            |  Native performance                    |  Slightly lower due to virtualization  |
| **Recommended For**        | Advanced users, final deployment       | Development, learning, experimentation  |


Keep on enjoying the OS , Good Luck !



