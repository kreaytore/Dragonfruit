# Dragonfruit for Godot
A Godot Plugin that allows you to add a customizable background image, slideshow, or video, to your Godot Code Editor's background!

By: [@kreaytore](https://x.com/kreaytore)

Tutorial: [https://youtu.be/2mn-ZqULlFc](https://youtu.be/2mn-ZqULlFc)

![An image of real Dragon Fruit](system/tool_theme/banner.jpg)

## What does Dragonfruit do?
Dragonfruit is a Godot Plugin that allows you to easily add a customizable background image, slideshow of images, or a background video, to your Godot Code Editor!

## Single Image Example
![Dragonfruit Image Example with Shinji](system/git-pics/image-ex.jpg)

If you want to add a Single Image, simply choose "Single Image", choose your image, and press "Apply". This image will save in your Code Editor, and it will not be removed if you close the Engine.
To remove the image, you can simply click the "clear" button, delete the custom theme in the "user_custom_bg_theme" folder, or delete the Custom Editor Theme path (located at "Editor > Editor Settings > Theme > Custom Theme" in the Engine).

## Slideshow Example
![Dragonfruit Slideshow Example with Frieren](system/git-pics/slide-ex.jpg)

Similarly to the Single Image, to have a Slideshow, add images to the Slideshow folder (user_slideshow_images).
Then, choose the switch time duration, and click "Apply". The switch time will begin counting down in seconds before the image changes.
Note that for every change, the Engine must pause for 1-3 seconds to make the change. This is unavoidable!

## Video Example
![Dragonfruit Video Example with Easy Breezy Video Background](system/git-pics/vid-ex.jpg)

Even though the picture above is just an image, in the Engine, it's actually a video of the "Keep Your Hands Off Eizouken!" opening, "[Easy Breezy](https://www.youtube.com/watch?v=8-91y7BJ8QA)".
To use the video feature, you need to place the video in the "user_video_bg" folder.

**IMPORTANT!!!** *As of December 10th, 2024, the Engine only allows .ogv/.ogg video files. You cannot use .mp4 or anything else. You would need to convert those files into .ogv/.ogg!*

After selecting your video and playing it, you can then adjust the Audio Bus, Volume, Mute, Pause, and Play the video.

**IMPORTANT!!!** *As of December 10th, 2024, the Engine does not support video seeking. So every time you switch a script, the video replays from the start. This will be fixed when the Engine supports video seeking!*

## Shader Editor Example
![Dragonfruit Video Example with Easy Breezy Video Background](system/git-pics/ShaderEditor.png)

## Code & Shader Editor Split Example
![Dragonfruit Video Example with Easy Breezy Video Background](system/git-pics/Split.png)

## Modulate
Because some images may be too hard on the eyes, there is a modulate feature, to allow for better code visibility.
Hex Code "#101010" recommended for best code visibility. 
Hex Code "#303030" recommended for best BG & Code visibility.
Hex Code "#222222" is the Default.

## Installation
1. Create an `addons` folder in your project.
2. 2a: Create a `Dragonfruit` folder inside `addons`. 2b: Or, instead of 2a, if you downloaded the .zip from this git, move the `Dragonfruit-main` folder from the .zip file into your `addons` folder, **and delete the *-main* part of *Dragonfruit-main* filename! This *-main* will cause issues!!!**
3. Copy all of the files from this git into the `Dragonfruit` folder (if you didn't do the 2b method).
4. Enable Dragonfruit in `Project Settings > Plugins`.
5. **RESTART YOUR ENGINE.** After enabling the plugin, you may see some errors in your console. Close and reopen the Editor. If you still see the errors, that's fine. Try adding a Single Image background. After it works, close and re-open the Engine one last time. Dragonfruit shouldn't give any more errors after that.
6. If you can't find the Dragonfruit dock once enabled, it should be on the right side, next to `Inspector | Node | History`.

This is how your addons folder should look:
```
res://
	addons
		Dragonfruit
```

**Remember, if you downloaded the .zip from git, and your file says `Dragonfruit-main`, you need to delete the *-main* part of the filename. Otherwise, issues will occur, and the plugin won't work!**


Thank you for installing!
