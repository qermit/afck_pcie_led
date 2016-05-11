# AFCK PCI express LED example

## Requirements
This project uses AFCK board description (https://github.com/qermit/ohwr_board_afck).

You should download it first and copy to your VIVADO_INSTALL_DIR/data/board/board_files/ohwr_board_afck

## Download

    git clone --recursive https://github.com/qermit/afck_pcie_led.git

or 

    git clone https://github.com/qermit/afck_pcie_led.git 
    cd afck_pcie_led
    git submodile init
    git submodule update

## Project re-creation

    vivado
    source create_project.tcl

