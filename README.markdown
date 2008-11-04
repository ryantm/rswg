RSWG
---

[RSWG](http://github.com/ryantm/rswg/) is a fully functional static website generator delivered to you in a single Rakefile. At around 200 lines of Ruby, it's easy to read and modify for your own purposes.

Features
---
* Haml templating
* Layouts
* Partials
* Template Pages (.hatl files)
* YAML based models

Install
---
        gem install rake haml sass
    	git clone git://github.com/ryantm/rswg.git sitename
        cd sitename
        rake

Tutorial
---

First we will make a webpage, edit `./src/pages/index.haml` and write:

        %h1 Hello World

Then type `rake` to build your website. 

        $ rake
        (in /home/ryan/rswgtest)
        Source last changed: Tue Nov 04 12:55:06 -0600 2008
        Deleting ./site
        Copying ./assets/. to ./site
        ./src/pages/index.haml to ./site/index.html
        Build took 0.00149 seconds.
        $ cat ./site/index.html 
        <h1>Hello World</h1>

License
-------

Copyright (c) 2008 Ryan Mulligan <http://www.ryantm.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
