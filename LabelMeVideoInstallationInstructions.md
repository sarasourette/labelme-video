Here you will find instructions to install and deploy LabelMeVideo in your own server.

# System requirements #

  1. Run an Apache server.
  1. Allow perl/CGI scripts to run.

# Installation instructions #

  1. Download the [LabelMeVideo source code](http://code.google.com/p/labelme-video/downloads/list)
  1. Unzip the downloaded file and copy the `LabelMeVideo` folder to where you want to run your application. For example, in Mac OS X, an Apache web server serves the user pages located in  `   /Users/<username>/Sites`, where `<username`> is your user name.  Copy the `LabelMeVideo` folder here and you should be able to see a directory listing of the files in this folder.
```
  http://localhost/~<username>/LabelMeVideo
```
  1. Open `http://localhost/~<username>/LabelMeVideo/helloWorld.pl`  in your web browser. You should get a screen like this. Otherwise, this means that your web server is not properly configured to run `cgi` scripts.
> > ![http://labelme-video.googlecode.com/svn/wiki/hello_world_cgi.png](http://labelme-video.googlecode.com/svn/wiki/hello_world_cgi.png)
  1. Open on `http://localhost/~<username>/LabelMeVideo/VLM.html` in your web browser. This opens the annotation tool which should look like this.
> > ![http://labelme-video.googlecode.com/svn/wiki/vlm_debug_screenshot.png](http://labelme-video.googlecode.com/svn/wiki/vlm_debug_screenshot.png)
  1. Set the correct permissions to the folders so the web server scripts can write and access the annotations in the folders. The web server code works by executing a cgi script that writes the annotations as xml files into the appropriate locations. Apache runs as a user in each platform/configuration differently (e.g. in Mac OS it might run as _nobody_ while in most Linux platforms as _www-data_). Change the permissions in the following directories such that such user has access to them. For example, in a standard Mac OS X configuration you would run:
```
sudo chown -R nobody  TmpVLMAnnotations VLMAnnotations Logs
```

> In most Linux distributions Apache runs as _www-data_:
```
sudo chown -R www-data  TmpVLMAnnotations VLMAnnotations Logs 
```
> Finally, test that everything works by annotating an object in one of the videos, saving it, and **refreshing** the browser to make sure the annotations saved correctly.


# Annotating your own videos #

You can annotate your own videos by copying them to the **`LabelMeVideo/VLMVideos`** folder.

## Video requirements ##


  * flv formatted. When encoding videos to flv, try to set for as many keyframes as possible. This step is important as a higher density of keyframes means that the video player will be able to seek into a particular frame with a higher precision. It is likely that the videos you have are not in the required format. To convert them to flv, you can use the following [ffmpeg](http://www.ffmpeg.org/) command:

```
 ffmpeg -i  <srcName>  -g 1 -y -an  -f flv -b 6400  -qcomp 1   <destName> -y
```


  * Metadata-injected. There are many metadata injectors available for flv video. A recommended one is [yamdi](http://yamdi.sourceforge.net/). This step is important as the video player relies on metadata information to create the video annotations

## Pointing the annotation tool to a different video ##
You can load a different video by editing the _folder_ and _fileName_ fields in the url. For example, if we wanted to load a video from the _videos\_iccv09/debug_ folder named _sun\_antonio\_fvehgmxkrvcgxgl.flv_, the url would be as follows:
```
http://localhost/~<username>/LabelMeVideo/VLM.html#folder=videos_iccv09/debug&fileName=sun_antonio_fvehgmxkrvcgxgl.flv
```

![http://labelme-video.googlecode.com/svn/wiki/vlm_street_screenshot.png](http://labelme-video.googlecode.com/svn/wiki/vlm_street_screenshot.png)

## Bounding box annotation mode ##
The default object annotation mode is set to polygon, but if you want to annotate with bounding boxes instead, you can add the _annotMode=box_ flag into the url:

```
http://localhost/~<username>/LabelMeVideo/VLM.html#folder=videos_iccv09/debug&fileName=sun_antonio_fvehgmxkrvcgxgl.flv&annotMode=box
```


## Annotations ##

Your annotations will be saved as xml files and can be found in the **`LabelMeVideo/VLMAnnotations`** folder.

## Contact us ##
If you have any questions  you can send an email to [labelme@csail.mit.edu]