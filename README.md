This program listens on port 9292 for a GET or POST request containing a TeX fragment representing a Tikz picture. It returns an SVG document, rendering the picture.

There are two request parameters:

> type: [ tikzpicture | tikzcd ]
> tex:  the body of the picture (i.e., everything after the `\begin{tikzpicture}` and before the
  `\end{tikzpicture}`). If you need some non-default Tikz libraries, you can embed a `\usetikzlibrary{...}` in your tex.

THe program requires a working TeX installation and the [pdf2svg](http://www.cityinthesky.co.uk/opensource/pdf2svg/) commandline application (which, in turn, requires the `poppler-glib` library).

* Customize the locations of `pdflatex` and pdf2svg` in the `config.yml` file. (Other configuration options include what interfaces the program binds to and what port it listens on.)
* Run
~~~~~
bundle install --path vendor/bundle
~~~~~

Then you can start the server with
~~~~~
bundle exec rackup
~~~~~
or
~~~~~
bundle exec rackup --daemon
~~~~~
to run it as a daemon.