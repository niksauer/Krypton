# Krypton
<a href="https://swift.org">
    <img src="http://img.shields.io/badge/swift-4.0-brightgreen.svg" alt="Swift 4.0">
</a>
<a href="https://github.com/niksauer/Krypton">
<img src="https://img.shields.io/badge/platform-ios-lightgrey.svg" alt="Supported Platforms">
</a>

The most advanced crypto currency tracker that uses public data only and requires no private keys.

### Preview
<img src="https://github.com/niksauer/Krypton/blob/master/Docs/Krypton_Promo.png">

### Setup 
1. `git clone <url>`
2. `git submodule update --recursive --init`

### Dependencies
- [NetworkKit](https://github.com/niksauer/NetworkKit)
- [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver)
- [SwiftKeccak](https://github.com/uport-project/SwiftKeccak)
- [ToolKit](https://github.com/niksauer/ToolKit)

### Submodules
This project uses `git submodules` to manage its dependencies. Therefore, setup becomes a two-step process. To **update to** the **newest availble commit** from the tracked branch of each submodule, run: `git submodule update --recursive --remote`.

Additionally, checkouts will happen in a `DETACHED-state`, i.e. any changes or updates pulled in, must be committed to its remote branch or this repository respectively in order to persist. For a full explanation, please read [ActiveState](https://www.activestate.com/blog/2014/05/getting-git-submodule-track-branch) and/or [StackOverflow](https://stackoverflow.com/questions/18770545/why-is-my-git-submodule-head-detached-from-master).
