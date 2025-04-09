# Barricade - Concert Memory App

![Barricade Header](/media/barricade-header.png)

## Overview

Barricade is an iOS app designed for concert enthusiasts who want to document and remember their live music experiences. The app allows users to track concerts they've attended, record setlists, and automatically identify songs using Shazam integration. Built with modern Swift technologies, Barricade offers a beautiful, intuitive interface for preserving your concert memories.

## Technology Stack

-   **Framework**: SwiftUI - Apple's modern declarative UI framework
-   **Data Storage**: SwiftData - Apple's latest persistence framework
-   **Media Handling**: AVKit, PhotosUI - For video capture and management
-   **Song Recognition**: ShazamKit - For automatic song identification
-   **Design**: Custom UI components with responsive, adaptive design
-   **Architecture**: MVVM (Model-View-ViewModel) pattern

## Key Features

-   **Concert Management**: Track past and upcoming concerts with artist, venue, and date information
-   **Automatic Song Detection**: Record concert clips and identify songs with Shazam integration
-   **Custom Setlists**: Build and reorder setlists for each concert
-   **Video Management**: Save video clips for each song in the setlist
-   **Rich Detail Views**: Colorful, engaging interfaces that adapt to each concert's aesthetic
-   **Future Concert Countdown**: Track days until upcoming shows

## Screenshots

|               Concerts List                |                Concert Detail                |              Songs Grid              |
| :----------------------------------------: | :------------------------------------------: | :----------------------------------: |
| ![Concerts List](/media/concerts-list.PNG) | ![Concert Detail](/media/concert-detail.PNG) | ![Songs Grid](/media/songs-grid.PNG) |

|               Song Detection                |             Song Page              |          Picture-in-Picture           |
| :-----------------------------------------: | :--------------------------------: | :-----------------------------------: |
| ![Song Detection](/media/song-detected.PNG) | ![Song Page](/media/song-page.PNG) | ![PiP Mode](/media/song-page-pip.PNG) |

## Technical Highlights

-   **SwiftData Integration**: Seamless persistence with Apple's modern object graph and persistence framework
-   **ShazamKit Implementation**: Audio fingerprinting to automatically identify songs from live recordings
-   **Video Processing Pipeline**: Optimized recording and playback of concert footage
-   **Adaptive Color Schemes**: Dynamic UI colors based on concert-specific themes
-   **Asynchronous Programming**: Leveraging Swift's async/await pattern for smooth media handling
-   **Error Handling**: Robust error recovery for media operations

## Design Philosophy

Barricade is built with the concert-goer in mind. The app acknowledges that live music moments are fleeting and precious, and aims to help users capture these memories without pulling them out of the moment. The intuitive, colorful interface is designed to evoke the emotion of each concert experience while providing practical functionality for tracking setlists.

## Future Roadmap

-   iCloud synchronization for cross-device access
-   Integration with music streaming services
-   Social sharing options for recordings
-   Faster video processing & detection
-   Smoother animations
