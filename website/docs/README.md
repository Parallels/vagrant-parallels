# Vagrant Parallels Documentation

There are sources for documentation pages:
https://parallels.github.io/vagrant-parallels/docs/

This is a [Middleman](https://middlemanapp.com) project, which builds a static
site from these source files.

## Contributions Welcome!

If you find a typo or you feel like you can improve the HTML, CSS, or
JavaScript, we welcome contributions. Feel free to open issues or pull
requests like any normal GitHub project, and we'll merge it in.

## Running the Site Locally

Running the site locally is simple. Clone this repo, switch to `website/docs/`
and run the following commands:

```
$ bundle
$ bundle exec middleman server
```

Your local copy of the site should be available by this URL: http://localhost:4567


## Deploy the Site to GitHub Pages

This example describes the deployment process of our official documentation
site,
https://parallels.github.io/vagrant-parallels/docs/. You will need
write permissions for the GitHub repo which you want to deploy to.

Make sure your current working directory is `website/docs/`. Then clone
"gh-pages" branch from the target repo to `./build` directory.
```
$ git clone -b gh-pages https://github.com/Parallels/vagrant-parallels ./build
```

If you want to deploy to your fork, put the URL of your fork repo instead:
```
$ git clone -b gh-pages https://github.com/<YOUR_USER>/vagrant-parallels ./build
```

Then run this command to build static pages with Middleman and deploy them to
the repo you've cloned before:

```
$ bundle
$ bundle exec middleman deploy --build-before
```

The site should be available on GitHub: https://parallels.github.io/vagrant-parallels/docs/
(or `https://<YOUR_USER>.github.io/vagrant-parallels/docs/`)


## Additional Links

- Middleman Deploy: https://github.com/middleman-contrib/middleman-deploy
- GitHub Pages: https://pages.github.com/
