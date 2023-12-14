# My First neovim Plugin
I always run into situations where there are alternate files to a given file and 
it was a very noticeable problem but the ecosystem did not provide a good system 
that match my needs. Therefore, I had to create this minimalist alternate type 
plugin where you have to choose one file and then connect to the alternate one.

Currently it works for my setup and the controls are very manual.

Also, I thought about performance the most when writing it and so I think it is 
pretty fast in raw movement but I have not tested it for massive projects stored.

Let's see if it breaks on me with more stuff and connections.

### Structure
Everything is inside the init.lua file and utils.lua is just function holders 
that I used for developing this project.
