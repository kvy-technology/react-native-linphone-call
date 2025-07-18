# React Native Linphone Call

A React Native library for making SIP calls using the Linphone SDK.

## Features

- Make and receive SIP calls
- Video calling support
- Audio device management (bluetooth, phone, loudspeaker)
- Microphone mute/unmute
- **Static image streaming** (NEW!) - Avoid camera permissions
- DTMF tone sending
- Call state management

## Installation

```bash
npm install react-native-linphone-call
# or
yarn add react-native-linphone-call
```

## Static Image Streaming (No Camera Permissions)

This library supports streaming static images instead of live video during SIP calls using Linphone's `setStaticPicture` API. This is perfect for:

- **Avoiding camera permissions** - No need to request camera access
- Privacy protection (showing a custom static image instead of live video)
- Bandwidth optimization
- Custom branding during calls

### Basic Usage

```typescript
import { useStaticImage, StaticImageConfig } from 'react-native-linphone-call';

function CallComponent() {
  const [isStaticImageActive, setStaticImage, clearStaticImage] = useStaticImage();

  const enableStaticImage = async () => {
    const config: StaticImageConfig = {
      imagePath: '/path/to/your/image.jpg', // Path to your custom image
      fps: 1.0 // Optional: frame rate (default is usually 1 fps)
    };

    const success = await setStaticImage(config);
    if (success) {
      console.log('Static image enabled - no camera permissions needed!');
    }
  };

  const disableStaticImage = async () => {
    const success = await clearStaticImage();
    if (success) {
      console.log('Static image disabled, back to camera');
    }
  };

  return (
    <View>
      <Text>Static Image: {isStaticImageActive ? 'Active' : 'Inactive'}</Text>
      <Button title="Enable Static Image" onPress={enableStaticImage} />
      <Button title="Disable Static Image" onPress={disableStaticImage} />
    </View>
  );
}
```

### Simple Integration with Call Flow

```typescript
import { useCall, useStaticImage } from 'react-native-linphone-call';

function SimpleCallComponent() {
  const { call, hangup } = useCall({
    onCallConnected: () => console.log('Call connected'),
    onCallReleased: () => console.log('Call ended')
  });

  const [isStaticImageActive, setStaticImage, clearStaticImage] = useStaticImage();

  const startCallWithStaticImage = async () => {
    // Set static image before making the call (no camera permissions needed)
    await setStaticImage({
      imagePath: 'profile_picture.jpg',
      fps: 1.0 // 1 frame per second
    });

    // Make the call
    await call('sip:user@domain.com');
  };

  const toggleVideoSource = async () => {
    if (isStaticImageActive) {
      await clearStaticImage();
    } else {
      await setStaticImage({
        imagePath: 'company_logo.jpg',
        fps: 0.5 // 1 frame every 2 seconds
      });
    }
  };

  return (
    <View>
      <Button title="Call with Static Image" onPress={startCallWithStaticImage} />
      <Button title="Toggle Video Source" onPress={toggleVideoSource} />
      <Button title="End Call" onPress={hangup} />
    </View>
  );
}
```

### Using React Native Assets

```typescript
import { useStaticImage } from 'react-native-linphone-call';

function CallWithStaticImage() {
  const [isStaticImageActive, setStaticImage, clearStaticImage] = useStaticImage();

  const enableProfilePicture = async () => {
    // For React Native assets, use the asset path
    const config: StaticImageConfig = {
      imagePath: 'profile_picture.jpg', // This should be in your assets folder
      fps: 1.0 // 1 frame per second
    };

    await setStaticImage(config);
  };

  return (
    <View>
      <Button
        title={isStaticImageActive ? "Show Camera" : "Show Profile Picture"}
        onPress={isStaticImageActive ? clearStaticImage : enableProfilePicture}
      />
    </View>
  );
}
```

## API Reference

### Hooks

#### `useStaticImage()`
Returns a tuple with:
- `isStaticImageActive: boolean` - Current static image state
- `setStaticImage: (config: StaticImageConfig) => Promise<boolean>` - Enable static image
- `clearStaticImage: () => Promise<boolean>` - Disable static image

#### `useCall(callbacks?)`
Returns call management functions including:
- `setStaticImage: (config: StaticImageConfig) => Promise<boolean>` - Set static image
- `clearStaticImage: () => Promise<boolean>` - Clear static image

### Types

#### `StaticImageConfig`
```typescript
interface StaticImageConfig {
  imagePath: string;  // Path to the static image file (required)
  fps?: number;       // Optional: frame rate for static picture (default is usually 1 fps)
}
```

## Platform-Specific Notes

### Android
- No camera permissions required when using static images
- Uses Linphone's `setStaticPicture` and `setStaticPictureFps` APIs
- Images should be placed in `android/app/src/main/assets/` or use full file paths
- Supports common image formats (JPEG, PNG, BMP)
- FPS can be configured for static picture streaming

### iOS
- No camera permissions required when using static images
- Uses Linphone's `setStaticPicture` and `setStaticPictureFps` APIs
- Images should be added to the Xcode project bundle or use full file paths
- Supports the same image formats as Android
- FPS can be configured for static picture streaming

## Benefits of Static Image Approach

1. **No Camera Permissions**: Users don't need to grant camera access
2. **Privacy**: Users can show a custom static image instead of live video
3. **Performance**: Static images use less bandwidth and processing power
4. **Reliability**: No camera hardware dependencies
5. **Customization**: Easy to brand with company logos or custom images
6. **Configurable FPS**: Control the frame rate of static image streaming

## Troubleshooting

### Static Image Not Working
1. Ensure the image file exists and is accessible
2. Check that the image format is supported (JPEG, PNG, BMP)
3. Verify the image path is correct for your platform
4. Make sure the SIP core is initialized before setting static image
5. Ensure the image file is readable by the application

### Performance Considerations
- Large images may impact performance
- Recommended image size: 640x480 to 1280x720
- Consider image compression for better performance
- Static images use less bandwidth than live video

### Memory Management
- Static images are loaded into memory by Linphone
- Clear static images when not needed to free memory
- Consider using smaller images for better performance
