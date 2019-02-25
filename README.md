# tex2svg

This program listens on port 9292 for a GET or POST request containing a TeX fragment representing a Tikz picture. It returns a rendering of the picture as an SVG document.

There are two request parameters:

>type: [ tikzpicture | tikzcd ]<br/>
> tex:  the body of the picture (i.e., everything after the `\begin{tikzpicture}` and before the
  `\end{tikzpicture}`). If you need some non-default Tikz libraries, you can embed a `\usetikzlibrary{...}` in your tex.

The `type` parameter is optional, and defaults to `tikzpicture`.

## Installation
The program requires a working TeX installation and the [pdf2svg](http://www.cityinthesky.co.uk/opensource/pdf2svg/) commandline application (which, in turn, requires the `poppler-glib` library).

* Customize the locations of `pdflatex` and `pdf2svg` in the `config.yml` file. (Other configuration options include what interfaces the program binds to and what port it listens on.)
* Run the command
~~~~~
bundle install --path vendor/bundle
~~~~~

## Running
Then you can start the server with
~~~~~
bundle exec rackup
~~~~~
or
~~~~~
bundle exec rackup --daemon
~~~~~
to run it as a daemon.

Only a [subset](https://golem.ph.utexas.edu/~distler/blog/itex2MMLcommands.html) of TeX commands are supported, in addition to the command supported by tikzpicture/tikzcd.

## Testing

The test suite is still a little sparse. You can run the tests with

~~~~~
bundle exec rake test
~~~~~