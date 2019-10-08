Wazuh macOS packages
====================

In this repository, you can find the necessary tools to build a Wazuh package for macOS.

## Tools needed to build the package

To build a Wazuh package you need to install the following tools:
- [Packages](http://s.sudre.free.fr/Software/Packages/about.html): You can install this on macOS using the `generate_wazuh_packages.sh` script in this repository.
- [brew](https://brew.sh/): You can install this on macOS using the `generate_wazuh_packages.sh` script in this repository.
- `git`: on macOS install with homebrew use `brew install git`.

## Building macOS packages

To build a macOS package, you need to download this repository and use the `generate_wazuh_packages.sh` script. This script will download the source code from the [wazuh/wazuh](https://github.com/wazuh/wazuh) repository and automatize the package generation.

1. Download this repository and go to the rpm directory:
    ```bash
    $ git clone https://github.com/wazuh/wazuh-packages && cd wazuh-packages/macos
    ```

2. Execute the `generate_wazuh_packages.sh` script to build the package. There are multiple parameters for selecting which package is going to be built, such as the install destination, etc. Also, you can install `Packages` using the script. Here you can see all the different parameters:
    ```shellsession
    $ ./generate_wazuh_packages.sh -h

    Usage: ./generate_wazuh_packages.sh [OPTIONS]

    Build options:
        -b, --branch <branch>         [Required] Select Git branch or tag e.g.
        -s, --store-path <path>       [Optional] Set the destination absolute path of package.
        -j, --jobs <number>           [Optional] Number of parallel jobs when compiling.
        -r, --revision <rev>          [Optional] Package revision that append to version e.g. x.x.x-rev
        -c, --checksum <path>         [Optional] Generate checksum on the desired path (by default, if no path is specified it will be generated on the same directory than the package).
        -h, --help                    [  Util  ] Show this help.
        -i, --install-deps            [  Util  ] Install build dependencies (Packages).
        -x, --install-xcode           [  Util  ] Install X-Code and brew. Can't be executed as root.

    Signing options:
        --keychain                    [Optional] Keychain where the Certificates are installed.
        --keychain-password           [Optional] Password of the keychain.
        --application-certificate     [Optional] Apple Developer ID certificate name to sign Apps and binaries.
        --installer-certificate       [Optional] Apple Developer ID certificate name to sign pkg.
        --notarize                    [Optional] Notarize the package for its distribution on macOS Catalina .
        --developer-id                [Optional] Your Apple Developer ID.
        --altool-password             [Optional] Temporary password to use altool from Xcode.


    ```
    * To build a wazuh-agent package for tag v3.7.2 with 4 jobs:
        `# sudo ./generate_wazuh_packages.sh -b v3.7.2 -j 4`.

    * To install `Packages` tool:
        `# sudo ./generate_wazuh_packages.sh -i `.

    * To install `brew` and `X-Code` tool:
        `$ ./generate_wazuh_packages.sh -x`.

3. When the execution finishes, you can find your `.pkg` packages in the specified folder (with the parameter `-s`), by default in the script path.


## Aditional information

### Building information

Use the `generate_wazuh_packages.sh` script for build packages for macOS.

The `package_files` contains some files used by the `Buildpackages` tool to generate the package. The most important file is `wazuh-agent-pkgproj`, which is used by `Buildpackages` to generate the package and have to be updated by the script with the specs and default Wazuh configurations. Also, there are two scripts, `postinstall.sh` and `preinstall.sh` that are loaded in the package to be executed during the installation, and the `build.sh` script defines how to compile the Wazuh Agent.

The specs folder contains the `pkgproj` files which are used to generate the `wazuh-agent.pkgproj` file.

### Apple notarization process

With macOS Mojave, Apple introduced the notarization process to improve the security of the final users. With macOS Mojave is recommended to notarize any installer/app, but with the release of macOS Catalina, it is mandatory to notarize any app or installer distributed outside of the App Store. To successfully notarize your package, you must have the following items:

- **Apple Developer ID**: this is used to request the certificates used to sign the binaries, the .pkg file and notarize the package. You can request one using this link. Besides, you need to enable two-factor authentication (_2FA_) and enroll in the Apple Developer program.
- **Apple Application Certificate** and **Apple Installer Certificate**: these certificates are used to sign the code and sign the .pkg file. In this [link](https://help.apple.com/developer-account/#/dev04fd06d56) you can find more information about how to request them. Once you have downloaded them, you must add them to your login keychain and make sure that `codesign` and `productsign` can access to the certificates and the private key.
- **Xcode 10 or greater**: to properly sign the binaries, sign the package and notarize it, you must install and download it.
- **Generate a temporary password for xcrun altool**: to notarize the package, you must use your Apple Developer ID and your password, but, for security reasons, only application specific passwords are allowed. To request one, you can follow this [link](https://support.apple.com/en-us/HT204397).

Once you have set up the environment, you can build and notarize the package as follows:

```shellsession
$ sudo ./generate_wazuh_packages.sh -b v3.10.2 -j 4 -r 1 --notarize \
    --keychain "/Users/your-user/Library/Keychains/login.keychain-db" \
    --application-certificate "Your Developer ID Application" \
    --installer-certificate "Your Developer ID Installer" \
    --developer-id "your_apple_id@email.com" --keychain-password "login_password" \
    --altool-password "temporary-password-for-altool"
```

The script will automatically sign the code and enable the _hardened runtime_, build the package and sign it, upload the package for its notarization and once it is notarized, the script will staple the notarization ticket to the package. Thanks to this, the package will be able to be installed in those hosts without an internet connection.

Finally, you can find the notarization result in the `wazuh-packages/macos/request_result.txt`.

### Additional information

- [Enable hardened runtime (macOS)](https://help.apple.com/xcode/mac/current/#/devf87a2ac8f).
- [About Code Signing](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html).
- [Code Signing Tasks](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html#//apple_ref/doc/uid/TP40005929-CH4-SW26).
- [Customizing the Notarization Workflow](https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution/customizing_the_notarization_workflow?language=objc).
- [Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements).
- [Hardened Runtime Entitlements](https://developer.apple.com/documentation/security/hardened_runtime_entitlements?language=objc).
- [Resolving Common Notarization Issues](https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution/resolving_common_notarization_issues).

### Common issues

- `xcrun: error: unable to find utility "altool", not a developer tool or in PATH`: this error appears when `xcrun` is unable to find altool. To solve it you will need to run:
    ```
    $ sudo xcode-select -r
    ```
    If this doesn't solve the issue, you will need to specify the path where Xcode is installed or unpacked:
    ```
    $ sudo xcode-select -s /path/to/Xcode.app
    ```
- `errSecInternalComponent` when running `codesign`: check the status of the login keychain. To solve it, you will need to close all the keychains and then run again the script.
- `error: The specified item could not be found in the keychain`: this error may appear if `codesign` or `productsign` can't access to the Certificates, the private key or both. Check in the Keychain of your Mac hosts if they can be read by `codesign` and `productsign`.

## More Packages

- [RPM](/rpms/README.md)
- [Debian](/debs/README.md)
- [AIX](/aix/README.md)
- [OVA](/ova/README.md)
- [KibanaApp](/wazuhapp/README.md)
- [SplunkApp](/splunkapp/README.md)
- [WPK](/wpk/README.md)
- [Solaris](/solaris/README.md)
- [HP-UX](/hpux/README.md)

## Contribute

If you want to contribute to our project please don't hesitate to send a pull request. You can also join our users [mailing list](https://groups.google.com/d/forum/wazuh) by sending an email to [wazuh+subscribe@googlegroups.com](mailto:wazuh+subscribe@googlegroups.com)or join to our Slack channel by filling this [form](https://wazuh.com/community/join-us-on-slack/) to ask questions and participate in discussions.

## License and copyright

WAZUH
Copyright (C) 2016-2019 Wazuh Inc.  (License GPLv2)