Sphero Web controller
=====================

### Requirements

* [Sphero Robot](https://magnum.travis-ci.com/akomba/btc-api-provider)
* Ruby
* Redis

### Installing

Clone this repository

Pair your Sphero with your PC or Mac (follow Sphero instructions)

Get your Sphero device path and add it to the .env file:

```sh
$ ls -ltrh /dev/tty.Sphero*
crw-rw-rw-  1 root  user   33,  12 May 22 19:02 /dev/tty.Sphero-RYP-AMP-SPP
crw-rw-rw-  1 root  user   33,  10 May 22 20:46 /dev/tty.Sphero-PYO-AMP-SPP
$ echo 'DEVICE_PATH="/dev/tty.Sphero-PYO-AMP-SPP"' > .env
```

Run Redis server in a separate terminal

```sh
$ redis-server
```
Run bundle install

```sh
$ bundle install
```

Run the web server

```sh
$ bundle exec thin start
```

Open a new terminal window

```sh
$ bundle exec ruby robot.rb
```

Open your browser in http://localhost:3000

Enjoy your sphero
