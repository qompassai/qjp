<!-- /qompassai/jetpack-nixos/README.md -->

<!-- ---------------------------- -->

<!-- Copyright (C) 2025 Qompass AI, All rights reserved -->

<h2> Qompass AI Jetpack NixOS Fork </h2>

![Repository Views](https://komarev.com/ghpvc/?username=qompassai-qjp)
![GitHub all releases](https://img.shields.io/github/downloads/qompassai/qjp/total?style=flat-square)

<a href="https://github.com/qompassai/nur-packages">
  <img src="https://img.shields.io/github/stars/qompassai/nur-packages?style=for-the-badge&logo=github&label=QompassAI%20NUR&color=003366" alt="QompassAI NUR Stars">
</a>
<br>

<a href="https://github.com/nix-community/NUR">
  <img src="https://img.shields.io/badge/NUR-Registered-success?style=flat-square&logo=nixos" alt="NUR Registered">
</a>
<a href="https://github.com/qompassai/nur-packages">
  <img src="https://img.shields.io/github/last-commit/qompassai/nur-packages?style=flat-square&label=Last%20Update" alt="Last Update">
</a>
<a href="https://github.com/qompassai/nur-packages/issues">
  <img src="https://img.shields.io/github/issues/qompassai/nur-packages?style=flat-square" alt="Issues">
</a>
<a href="https://github.com/qompassai/nur-packages/actions">
  <img src="https://img.shields.io/github/actions/workflow/status/qompassai/nur-packages/ci.yml?style=flat-square&label=Build" alt="Build Status">
</a>
<br>

<a href="https://developer.nvidia.com/cuda-toolkit">
  <img src="https://img.shields.io/badge/CUDA-12.8-76B900?style=flat-square&logo=nvidia&logoColor=white" alt="CUDA Support">
</a>
<a href="https://github.com/qompassai/qjp">
  <img src="https://img.shields.io/badge/Jetpack-NixOS-4A90E2?style=flat-square&logo=nixos&logoColor=white" alt="Jetpack NixOS">
</a>
<a href="https://github.com/anduril/qjp">
  <img src="https://img.shields.io/badge/Anduril-Fork-FF6B35?style=flat-square&logo=github&logoColor=white" alt="Anduril Fork">
</a>
<a href="https://openquantumsafe.org">
  <img src="https://img.shields.io/badge/PQC-OpenSSL%203.5-1B1F23?style=flat-square&logo=openssl&logoColor=white" alt="Post-Quantum Crypto">
</a>
<br>

<a href="#ai-packages">
  <img src="https://img.shields.io/badge/AI%2F-Packages-00ACC1?style=flat-square&logo=tensorflow&logoColor=white" alt="AI/ML Packages">
</a>
<a href="#quantum-packages">
  <img src="https://img.shields.io/badge/Quantum-Packages-7B1FA2?style=flat-square&logo=atom&logoColor=white" alt="Quantum Packages">
</a>
<a href="#security-packages">
  <img src="https://img.shields.io/badge/Security-Packages-D32F2F?style=flat-square&logo=kalilinux&logoColor=white" alt="Security Packages">
</a>
  <a href="https://www.gnu.org/licenses/agpl-3.0"><img src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" alt="License: AGPL v3"></a>
  <a href="./LICENSE-QCDA"><img src="https://img.shields.io/badge/license-Q--CDA-lightgrey.svg" alt="License: Q-CDA"></a>
</p>

______________________________________________________________________

<details id="How to Use this Repository">
  <summary><strong>How to Use This Repository</strong></summary>

This repository packages components from NVIDIA's [Jetpack SDK](https://developer.nvidia.com/embedded/jetpack) for use with NixOS, including:

- Platform firmware flashing scripts
- A 5.10 Linux kernel from NVIDIA, which includes some open-source drivers like nvgpu
- An [EDK2-based UEFI firmware](https://github.com/NVIDIA/edk2-nvidia)
- ARM Trusted Firmware / OP-TEE
- Additional packages for:
  - GPU computing: CUDA, CuDNN, TensorRT
  - Multimedia: hardware accelerated encoding/decoding with V4L2 and gstreamer plugins
  - Graphics: Wayland, GBM, EGL, Vulkan
  - Power/fan control: nvpmodel, nvfancontrol

This package is based on the Jetpack 5 release, and will only work with devices supported by Jetpack 5.1:

- Jetson Orin AGX
- Jetson Orin NX
- Jetson Xavier AGX
- Jetson Xavier NX

The Jetson Nano, TX2, and TX1 devices are _not_ supported, since support for them was dropped upstream in Jetpack 5.
In the future, when the Orin Nano is released, it should be possible to make it work as well.

## Getting started

### Flashing UEFI firmware

This step may be optional if your device already has recent-enough firmware which includes UEFI. (Post-Jetpack 5. Only newly shipped Orin devices might have this)
If you are unsure, I'd recommend flashing the firmware anyway.

Plug in your Jetson device, press the "power" button" and ensure the power light turns on.
Then, to enter recovery mode, hold the "recovery" button down while pressing the "reset" button.
Connect via USB and verify the device is in recovery mode.

```shell
$ lsusb | grep -i NVIDIA
Bus 003 Device 013: ID 0955:7023 NVIDIA Corp. APX
```

On an x86_64 machine (some of NVIDIA's precompiled components like `tegrarcm_v2` are only built for x86_64),
build and run (as root) the flashing script which corresponds to your device (making sure to
replace `xavier-agx` with the name of your device, use `nix flake show` to see options):

```shell
$ nix build github:anduril/jetpack-nixos#flash-xavier-agx-devkit
$ sudo ./result/bin/flash-xavier-agx-devkit
```

At this point, your device should have a working UEFI firmware accessible either a monitor/keyboard, or via UART.

### Installation ISO

Now, build and write the customized installer ISO to a USB drive:

```shell
$ nix build github:anduril/jetpack-nixos#iso_minimal
$ sudo dd if=./result/iso/nixos-22.11pre-git-aarch64-linux.iso of=/dev/sdX bs=1M oflag=sync status=progress
```

(Replace `/dev/sdX` with the correct path for your USB drive)

As an alternative, you could also try the generic ARM64 multiplatform ISO from NixOS. See https://nixos.wiki/wiki/NixOS_on_ARM/UEFI
(Last I tried, this worked on Xavier AGX but not Orin AGX. We should do additional testing to see exactly what is working or not with the vendor kernel vs. mainline kernel)

### Installing NixOS

Insert the USB drive into the Jetson device.
On the AGX devkits, I've had the best luck plugging into the USB-C slot above the power barrel jack.
You may need to try a few USB options until you find one that works with both the UEFI firmware and the Linux kernel.

Press power / reset as needed.
When prompted, press ESC to enter the UEFI firmware menu.
In the "Boot Manager", select the correct USB device and boot directly into it.

Follow the [NixOS manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation) for installation instructions, using the instructions specific to UEFI devices.
Include the following in your `configuration.nix` (or the equivalent in your `flake.nix`) before installing:

```nix
{
  imports = [
    (builtins.fetchTarball "https://github.com/anduril/jetpack-nixos/archive/master.tar.gz" + "/modules/default.nix")
  ];

  hardware.nvidia-jetpack.enable = true;
  hardware.nvidia-jetpack.som = "xavier-agx"; # Other options include orin-agx, xavier-nx, and xavier-nx-emmc
  hardware.nvidia-jetpack.carrierBoard = "devkit";
}
```

The Xavier AGX contains some critical firmware paritions on the eMMC.
If you are installing NixOS to the eMMC, be sure to not remove these partitions!
You can remove and replace the "UDA" partition if you want to install NixOS to the eMMC.
Better yet, install to an SSD.

After installing, reboot and pray!

##### Xavier AGX note:

On all recent Jetson devices besides the Xavier AGX, the firmware stores the UEFI variables on a flash chip on the QSPI bus.
However, the Xavier AGX stores it on a `uefi_variables` partition on the eMMC.
This means that it cannot support runtime UEFI variables, since the UEFI runtime drivers to access the eMMC would conflict with the Linux kernel's drivers for the eMMC.
Concretely, that means that you cannot modify the EFI variables from Linux, so UEFI bootloaders will not be able to create an EFI boot entry and reorder the boot options.
You may need to enter the firmware menu and reorder it manually so NixOS will boot first.
(See [this issue](https://forums.developer.nvidia.com/t/using-uefi-runtime-variables-on-xavier-agx/227970))

### Graphical Output

As of 2023-12-09, the status of graphical output on Jetsons is described below.
If you have problems with configurations that are expected to work, try different ports (HDMI/DP/USB-C), different cables, and rebooting with the cables initially connected or disconnected.

#### Linux Console

On Orin AGX/NX/Nano, the Linux console does not seem to work at all on the HDMI/DisplayPort.
This may be an upstream limitation (not jetpack-nixos specific).

On Xavier AGX and Xavier NX, add `boot.kernelParams = [ "fbcon=map:<n>" ]`, replacing `<n>` with the an integer according to the following:

Xavier AGX devkit:

- 0 for front USB-C port (recovery port)
- 1 for rear USB-C port (above power barrel jack)
- 2 for rear HDMI port

Xavier NX devkit:

- 0 for DisplayPort
- 1 for HDMI

Given the unreliability of graphical console output on Jetson devices, I recommend using the serial port as the go-to for troubleshooting.

#### X11

Set `hardware.nvidia-jetpack.modesetting.enable = false;`.
This is currently the default, but the default may change in the future.
LightDM+i3 and LightDM+Gnome have been tested working. (Remember to add the user to the "video" group)
GDM apparently does not currently work.

#### Wayland

Set `hardware.nvidia-jetpack.modesetting.enable = true;`
Weston and sway have been tested working on Orin devices, but do not work on Xavier devices.

### Updating firmware from device

Recent versions of Jetpack (>=5.1) support updating the device firmware from the device using the UEFI Capsule update mechanism.
This can be done as a more convenient alternative to physically attaching to the device and re-running the flash script.
These updates can be performed automatically after a `nixos-rebuild switch` if the `hardware.nvidia-jetpack.bootloader.autoUpdate` setting is set to true.
Otherwise, the instructions to apply the update manually are below.

To determine if the currently running firmware matches the software, run, `ota-check-firmware`:

```
$ ota-check-firmware
Current firmware version is: 35.6.1
Current software version is: 35.6.1
```

If these versions do not match, you can update your firmware using the UEFI Capsule update mechanism. The procedure to do so is below:

To build a capsule update file, build the
`config.system.build.uefiCapsuleUpdate` attribute from your NixOS build. For the standard devkit configurations supported in this repository, one could also run (for example),
`nix build .#uefi-capsule-update-xavier-nx-emmc-devkit`. This will produce a file that you can scp (no need for `nix copy`) to the device to update.

Once the file is on the device, run:

```
$ sudo ota-apply-capsule-update example.Cap
$ sudo reboot
```

(Assuming `example.Cap` is the file you copied to the device.) While the device is rebooting, do not disconnect power. You should be able to see a progress bar while the update is being applied. The capsule update works by updating the non-current slot A/B firmware partitions, and then rebooting into the new slot. So, if the new firmware does not boot up to UEFI, it should theoretically rollback to the original firmware.

After rebooting, you can run `ota-check-firmware` to see if the firmware version had changed.
Additionally, you can get more detailed information on the status of the firmware update by running:

```
$ sudo nvbootctrl dump-slots-info
```

The Capsule update status is one of the following integers:

- 0 - No Capsule update
- 1 - Capsule update successfully
- 2 - Capsule install successfully but boot new firmware failed
- 3 - Capsule install failed

### UEFI Capsule Authentication

To ensure only authenticated capsule updates are applied to the device, you can
build the UEFI firmware and each subsequent capsule update using your own signing keys.
An overview of the key generation can be found at [EDK2 Capsule Signing](https://github.com/tianocore/tianocore.github.io/wiki/Capsule-Based-System-Firmware-Update-Generate-Keys).

To include your own signing keys in the EDK2 build and capsule update, make
sure the option `hardware.nvidia-jetpack.firmware.uefi.capsuleAuthentication.enable`
is turned on and each signing key option is set.

### OCI Container Support

You can run OCI containers with jetpack-nixos by enabling the following nixos options:

```nix
{
  virtualisation.podman.enable = true;
  virtualisation.podman.enableNvidia = true;
}
```

Note that on newer nixpkgs the `virtualisation.{docker,podman}.enableNvidia` option is deprecated in favor of using `hardware.nvidia-container-toolkit.enable` instead. This new option does not work yet with Jetson devices, see [this issue](https://github.com/nixos/nixpkgs/issues/344729).

To run a container with access to nvidia hardware, you must specify a device to
passthrough to the container in the [CDI](https://github.com/cncf-tags/container-device-interface/blob/main/SPEC.md#overview)
format. By default, there will be a single device setup of the kind
"nvidia.com/gpu" named "all". To use this device, pass
`--device=nvidia.com/gpu=all` when starting your container. If you need to
configure more CDI devices on the NixOS host, just note that the path
/var/run/cdi/jetpack-nixos.yaml will be taken by jetpack-nixos.

As of December 2023, Docker does not have a released version that supports the
CDI specification, so Podman is recommended for running containers on Jetson
devices. Docker is set to get experimental CDI support in their version 25
release.

## Configuring CUDA for Nixpkgs

> [!NOTE]
>
> Nixpkgs as created by NixOS configurations using JetPack NixOS modules is automatically configured to enable CUDA support for Jetson devices.
> This behavior can be disabled by setting `hardware.nvidia-jetpack.configureCuda` to `false`, in which case Nixpkgs should be configured as described in [Importing Nixpkgs](#importing-nixpkgs).

### Importing Nixpkgs

To configure Nixpkgs to advertise CUDA support, ensure it is imported with a config similar to the following:

```nix
{
  config = {
    allowUnfree = true;
    cudaSupport = true;
    cudaCapabilities = [ "7.2" "8.7" ];
  };
}
```

> [!IMPORTANT]
>
> The `config` attribute set is not part of Nixpkgs' fixed-point, so re-evaluation only occurs through use of `pkgs.extend`.
> It is imperative that Nixpkgs is properly configured during import.

Breaking down these components:

- `allowUnfree`: CUDA binaries have an unfree license
- `cudaSupport`: Packages in Nixpkgs enabled CUDA acceleration based on this value
- `cudaCapabilities`: [Specific CUDA architectures](https://developer.nvidia.com/cuda-gpus) for which CUDA-accelerated packages should generate device code

> [!IMPORTANT]
>
> While supplying `config.cudaCapabilities` is optional for x86 and SBSA systems, it is mandatory for Jetsons, as Jetson capabilities are not included in the defaults.
>
> Furthermore, it is strongly recommended that `config.cudaCapabilities` is always set explicitly, given it reduces build times, produces smaller closures, and provides the CUDA compiler more opportunities for optimization.

So, the above configuration allows building CUDA-accelerated packages (through `allowUnfree` and `cudaSupport`) and tells Nixpkgs to generate device code targeting Xavier (`"7.2"`) and Orin (`"8.7"`).

### Re-using `jetpack-nixos`'s CUDA package set

While our overlay exposes a CUDA package set through `pkgs.nvidia-jetpack.cudaPackages`, packages like OpenCV and PyTorch don't know to look there.
Worse yet, even if we overrode the CUDA package sets they recieved, we would need to do the same for all their transitive dependencies!

To make `jetpack-nixos`'s CUDA package set the default, provide Nixpkgs with this overlay:

```nix
final: _: { inherit (final.nvidia-jetpack) cudaPackages; }
```

## Additional Links

Much of this is inspired by the great work done by [OpenEmbedded for Tegra](https://github.com/OE4T).
We also use the cleaned-up vendor kernel from OE4T.

</details>

<details id="About The Founder">
  <summary><strong>About the Founder</strong></summary>

<div align="center">
  <p>Matthew A. Porter<br>
  Founder & CEO<br>
  Qompass AI, Spokane, WA</p>

<h3>Publications</h3>
  <p>
    <a href="https://orcid.org/0000-0002-0302-4812">
      <img src="https://img.shields.io/badge/ORCID-0000--0002--0302--4812-green?style=flat-square&logo=orcid" alt="ORCID">
    </a>
    <a href="https://www.researchgate.net/profile/Matt-Porter-7">
      <img src="https://img.shields.io/badge/ResearchGate-Open--Research-blue?style=flat-square&logo=researchgate" alt="ResearchGate">
    </a>
    <a href="https://zenodo.org/communities/qompassai">
      <img src="https://img.shields.io/badge/Zenodo-Publications-blue?style=flat-square&logo=zenodo" alt="Zenodo">
    </a>
  </p>

<h3>Developer Programs</h3>

[![NVIDIA Developer](https://img.shields.io/badge/NVIDIA-Developer_Program-76B900?style=for-the-badge&logo=nvidia&logoColor=white)](https://developer.nvidia.com/)
[![Meta Developer](https://img.shields.io/badge/Meta-Developer_Program-0668E1?style=for-the-badge&logo=meta&logoColor=white)](https://developers.facebook.com/)
[![HackerOne](https://img.shields.io/badge/-HackerOne-%23494649?style=for-the-badge&logo=hackerone&logoColor=white)](https://hackerone.com/phaedrusflow)
[![HuggingFace](https://img.shields.io/badge/HuggingFace-qompass-yellow?style=flat-square&logo=huggingface)](https://huggingface.co/qompass)
[![Epic Games Developer](https://img.shields.io/badge/Epic_Games-Developer_Program-313131?style=for-the-badge&logo=epic-games&logoColor=white)](https://dev.epicgames.com/)

<h3>Professional Profiles</h3>
  <p>
    <a href="https://www.linkedin.com/in/matt-a-porter-103535224/">
      <img src="https://img.shields.io/badge/LinkedIn-Matt--Porter-blue?style=flat-square&logo=linkedin" alt="Personal LinkedIn">
    </a>
    <a href="https://www.linkedin.com/company/95058568/">
      <img src="https://img.shields.io/badge/LinkedIn-Qompass--AI-blue?style=flat-square&logo=linkedin" alt="Startup LinkedIn">
    </a>
  </p>

<h3>Social Media</h3>
  <p>
    <a href="https://twitter.com/PhaedrusFlow">
      <img src="https://img.shields.io/badge/Twitter-@PhaedrusFlow-blue?style=flat-square&logo=twitter" alt="X/Twitter">
    </a>
    <a href="https://www.instagram.com/phaedrusflow">
      <img src="https://img.shields.io/badge/Instagram-phaedrusflow-purple?style=flat-square&logo=instagram" alt="Instagram">
    </a>
    <a href="https://www.youtube.com/@qompassai">
      <img src="https://img.shields.io/badge/YouTube-QompassAI-red?style=flat-square&logo=youtube" alt="YouTube">
    </a>
  </p>

</div>
</details>

<details id="Support and Funding">
  <summary><strong>💰 Support & Funding</strong></summary>

<div align="center">

<table>
<tr>
<th align="center">🏛️ Pre-Seed Funding 2023-2025</th>
<th align="center">🏆 Amount</th>
<th align="center">📅 Date</th>
</tr>
<tr>
<td><a href="https://github.com/qompassai/r4r" title="RJOS/Zimmer Biomet Research Grant Repository">RJOS/Zimmer Biomet Research Grant</a></td>
<td align="center">$30,000</td>
<td align="center">March 2024</td>
</tr>
<tr>
<td><a href="https://github.com/qompassai/PathFinders" title="GitHub Repository">Pathfinders Intern Program</a><br>
<small><a href="https://www.linkedin.com/posts/evergreenbio_bioscience-internships-workforcedevelopment-activity-7253166461416812544-uWUM/" target="_blank">View on LinkedIn</a></small></td>
<td align="center">$2,000</td>
<td align="center">October 2024</td>
</tr>
</table>

<br>
<h4>🤝 Support Our Mission</h4>

[![GitHub Sponsors](https://img.shields.io/badge/GitHub-Sponsor-EA4AAA?style=for-the-badge&logo=github-sponsors&logoColor=white)](https://github.com/sponsors/phaedrusflow)
[![Patreon](https://img.shields.io/badge/Patreon-Support-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://patreon.com/qompassai)
[![Liberapay](https://img.shields.io/badge/Liberapay-Donate-F6C915?style=for-the-badge&logo=liberapay&logoColor=black)](https://liberapay.com/qompassai)
[![Open Collective](https://img.shields.io/badge/Open%20Collective-Support-7FADF2?style=for-the-badge&logo=opencollective&logoColor=white)](https://opencollective.com/qompassai)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/phaedrusflow)

<details>
<summary><strong>🔐 Cryptocurrency Donations</strong></summary>

**Monero (XMR):**

42HGspSFJQ4MjM5ZusAiKZj9JZWhfNgVraKb1eGCsHoC6QJqpo2ERCBZDhhKfByVjECernQ6KeZwFcnq8hVwTTnD8v4PzyH

</details>

<p><i>Funding helps us continue our research at the intersection of AI, healthcare, and education</i></p>

📄 **[Complete funding configuration](./FUNDING.yml)**

</div>
</details>

<details id="FAQ">
  <summary><strong>Frequently Asked Questions</strong></summary>

### Q: How do you mitigate against bias?

**TLDR - we do math to make AI ethically useful**

### A: We delineate between mathematical bias (MB) - a fundamental parameter in neural network equations - and algorithmic/social bias (ASB). While MB is optimized during model training through backpropagation, ASB requires careful consideration of data sources, model architecture, and deployment strategies. We implement attention mechanisms for improved input processing and use legal open-source data and secure web-search APIs to help mitigate ASB.

[AAMC AI Guidelines | One way to align AI against ASB](https://www.aamc.org/about-us/mission-areas/medical-education/principles-ai-use)

### AI Math at a glance

## Forward Propagation Algorithm

$$
y = w_1x_1 + w_2x_2 + ... + w_nx_n + b
$$

Where:

- $y$ represents the model output
- $(x_1, x_2, ..., x_n)$ are input features
- $(w_1, w_2, ..., w_n)$ are feature weights
- $b$ is the bias term

### Neural Network Activation

For neural networks, the bias term is incorporated before activation:

$$
z = \\sum\_{i=1}^{n} w_ix_i + b
$$
$$
a = \\sigma(z)
$$

Where:

- $z$ is the weighted sum plus bias
- $a$ is the activation output
- $\\sigma$ is the activation function

### Attention Mechanism- aka what makes the Transformer (The "T" in ChatGPT) powerful

- [Attention High level overview video](https://www.youtube.com/watch?v=fjJOgb-E41w)

- [Attention Is All You Need Arxiv Paper](https://arxiv.org/abs/1706.03762)

The Attention mechanism equation is:

$$
\\text{Attention}(Q, K, V) = \\text{softmax}\\left( \\frac{QK^T}{\\sqrt{d_k}} \\right) V
$$

Where:

- $Q$ represents the Query matrix
- $K$ represents the Key matrix
- $V$ represents the Value matrix
- $d_k$ is the dimension of the key vectors
- $\\text{softmax}(\\cdot)$ normalizes scores to sum to 1

### Q: Do I have to buy a Linux computer to use this? I don't have time for that!

### A: No. You can run Linux and/or the tools we share alongside your existing operating system:

- Windows users can use Windows Subsystem for Linux [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
- Mac users can use [Homebrew](https://brew.sh/)
- The code-base instructions were developed with both beginners and advanced users in mind.

### Q: Do you have to get a masters in AI?

### A: Not if you don't want to. To get competent enough to get past ChatGPT dependence at least, you just need a computer and a beginning's mindset. Huggingface is a good place to start.

- [Huggingface](https://docs.google.com/presentation/d/1IkzESdOwdmwvPxIELYJi8--K3EZ98_cL6c5ZcLKSyVg/edit#slide=id.p)

### Q: What makes a "small" AI model?

### A: AI models ~=10 billion(10B) parameters and below. For comparison, OpenAI's GPT4o contains approximately 200B parameters.

</details>

<details id="Dual-License Notice">
  <summary><strong>What a Dual-License Means</strong></summary>

### Protection for Vulnerable Populations

The dual licensing aims to address the cybersecurity gap that disproportionately affects underserved populations. As highlighted by recent attacks<sup><a href="#ref1">[1]</a></sup>, low-income residents, seniors, and foreign language speakers face higher-than-average risks of being victims of cyberattacks. By offering both open-source and commercial licensing options, we encourage the development of cybersecurity solutions that can reach these vulnerable groups while also enabling sustainable development and support.

### Preventing Malicious Use

The AGPL-3.0 license ensures that any modifications to the software remain open source, preventing bad actors from creating closed-source variants that could be used for exploitation. This is especially crucial given the rising threats to vulnerable communities, including children in educational settings. The attack on Minneapolis Public Schools, which resulted in the leak of 300,000 files and a $1 million ransom demand, highlights the importance of transparency and security<sup><a href="#ref8">[8]</a></sup>.

### Addressing Cybersecurity in Critical Sectors

The commercial license option allows for tailored solutions in critical sectors such as healthcare, which has seen significant impacts from cyberattacks. For example, the recent Change Healthcare attack<sup><a href="#ref4">[4]</a></sup> affected millions of Americans and caused widespread disruption for hospitals and other providers. In January 2025, CISA<sup><a href="#ref2">[2]</a></sup> and FDA<sup><a href="#ref3">[3]</a></sup> jointly warned of critical backdoor vulnerabilities in Contec CMS8000 patient monitors, revealing how medical devices could be compromised for unauthorized remote access and patient data manipulation.

### Supporting Cybersecurity Awareness

The dual licensing model supports initiatives like the Cybersecurity and Infrastructure Security Agency (CISA) efforts to improve cybersecurity awareness<sup><a href="#ref7">[7]</a></sup> in "target rich" sectors, including K-12 education<sup><a href="#ref5">[5]</a></sup>. By allowing both open-source and commercial use, we aim to facilitate the development of tools that support these critical awareness and protection efforts.

### Bridging the Digital Divide

The unfortunate reality is that too many individuals and organizations have gone into a frenzy in every facet of our daily lives<sup><a href="#ref6">[6]</a></sup>. These unfortunate folks identify themselves with their talk of "10X" returns and building towards Artificial General Intelligence aka "AGI" while offering GPT wrappers. Our dual licensing approach aims to acknowledge this deeply concerning predatory paradigm with clear eyes while still operating to bring the best parts of the open-source community with our services and solutions.

### Recent Cybersecurity Attacks

Recent attacks underscore the importance of robust cybersecurity measures:

- The Change Healthcare cyberattack in February 2024 affected millions of Americans and caused significant disruption to healthcare providers.
- The White House and Congress jointly designated October 2024 as Cybersecurity Awareness Month. This designation comes with over 100 actions that align the Federal government and public/private sector partners are taking to help every man, woman, and child to safely navigate the age of AI.

By offering both open source and commercial licensing options, we strive to create a balance that promotes innovation and accessibility. We address the complex cybersecurity challenges faced by vulnerable populations and critical infrastructure sectors as the foundation of our solutions, not an afterthought.

### References

<div id="footnotes">
<p id="ref1"><strong>[1]</strong> <a href="https://www.whitehouse.gov/briefing-room/statements-releases/2024/10/02/international-counter-ransomware-initiative-2024-joint-statement/">International Counter Ransomware Initiative 2024 Joint Statement</a></p>

<p id="ref2"><strong>[2]</strong> <a href="https://www.cisa.gov/sites/default/files/2025-01/fact-sheet-contec-cms8000-contains-a-backdoor-508c.pdf">Contec CMS8000 Contains a Backdoor</a></p>

<p id="ref3"><strong>[3]</strong> <a href="https://www.aha.org/news/headline/2025-01-31-cisa-fda-warn-vulnerabilities-contec-patient-monitors">CISA, FDA warn of vulnerabilities in Contec patient monitors</a></p>

<p id="ref4"><strong>[4]</strong> <a href="https://www.chiefhealthcareexecutive.com/view/the-top-10-health-data-breaches-of-the-first-half-of-2024">The Top 10 Health Data Breaches of the First Half of 2024</a></p>

<p id="ref5"><strong>[5]</strong> <a href="https://www.cisa.gov/K12Cybersecurity">CISA's K-12 Cybersecurity Initiatives</a></p>

<p id="ref6"><strong>[6]</strong> <a href="https://www.ftc.gov/business-guidance/blog/2024/09/operation-ai-comply-continuing-crackdown-overpromises-ai-related-lies">Federal Trade Commission Operation AI Comply: continuing the crackdown on overpromises and AI-related lies</a></p>

<p id="ref7"><strong>[7]</strong> <a href="https://www.whitehouse.gov/briefing-room/presidential-actions/2024/09/30/a-proclamation-on-cybersecurity-awareness-month-2024/">A Proclamation on Cybersecurity Awareness Month, 2024</a></p>

<p id="ref8"><strong>[8]</strong> <a href="https://therecord.media/minneapolis-schools-say-data-breach-affected-100000/">Minneapolis school district says data breach affected more than 100,000 people</a></p>
</div>
</details>
