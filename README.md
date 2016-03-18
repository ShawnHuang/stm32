```
sudo apt-get install zlib1g-dev libsdl1.2-dev automake* autoconf* libtool libpixman-1-dev

64bit

sudo apt-get install lib32gcc1 lib32ncurses5
```

```
cd  /
sudo tar jxvf toolchain-2012_03.tar.bz2
```

```
#back to this project

git clone git://github.com/beckus/qemu_stm32.git

cd qemu_stm32
./configure --disable-werror --enable-debug \
    --target-list="arm-softmmu" \
    --extra-cflags=-DDEBUG_CLKTREE \
    --extra-cflags=-DDEBUG_STM32_RCC \
    --extra-cflags=-DDEBUG_STM32_UART \
    --extra-cflags=-DSTM32_UART_NO_BAUD_DELAY \
    --extra-cflags=-DSTM32_UART_ENABLE_OVERRUN
make
cd ..
export PATH=/usr/local/csl/arm-2012.03/bin:$PATH
make
make QEMURUN
```
