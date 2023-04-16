# Author: Nicolas Gabriel Cotti (ngcotti@gmail.com)

#------------------------------------------------------------------------------
# Makefile Initialization
#------------------------------------------------------------------------------
SHELL=/bin/bash
.ONESHELL:
.POSIX:
.EXPORT_ALL_VARIABLES:
.DELETE_ON_ERROR:
.SILENT:
.DEFAULT_GOAL := help

#------------------------------------------------------------------------------
# User modifiable variables
#------------------------------------------------------------------------------
# Which compiler, linker, assembler and binutils to use, e.g.:
# arm-none-eabi, arm-linux-gnueabihf, (left empty), etc
toolchain := arm-none-eabi

# User specific flags for C compiler.
compiler_flags := -c -Wall

# User specific flags for Assembler
assembler_flags := 

# Direction to the linker script (can be empty)
linker_script := 

# User specific linker flags.
linker_flags := 

# List of header files' directories (don't use "./").
header_dirs := inc inc/sub_inc

# List of source files' directories (don't use "./")
source_dirs := src src/sub_src

# Name of the final executable (without extension)
executable_name := exe

#------------------------------------------------------------------------------
# Binutils 
#------------------------------------------------------------------------------
cc 			:= ${toolchain}-gcc
as 			:= ${toolchain}-as
linker 		:= ${toolchain}-ld
objdump 	:= ${toolchain}-objdump
objcopy 	:= ${toolchain}-objcopy

#------------------------------------------------------------------------------
# File extensions
#------------------------------------------------------------------------------
obj_ext 		:= .o
c_ext 			:= .c
h_ext 			:= .h
asm_ext 		:= .s
elf_ext 		:= .elf
bin_ext 		:= .bin
obj_header_ext 	:= .header
dasm_ext		:= .dasm

#------------------------------------------------------------------------------
# Miscelaneous constants
#------------------------------------------------------------------------------
print_checkmark 	:= printf "\\033[0;32m\\u2714\n\\033[0m"
print_cross 		:= printf "\\u274c\n"

#------------------------------------------------------------------------------
# File location
#------------------------------------------------------------------------------
build_dir	:= build
info_dir 	:= info
elf_file 	:= ${build_dir}/${executable_name}${elf_ext}
bin_file 	:= ${build_dir}/${executable_name}${bin_ext}

# List all C source files as "source_dir/source_file"
define c_source_files !=
	for dir in ${source_dirs}; do
		ls $${dir}/*${c_ext} 2> /dev/null
	done
endef

# List all assembly source files as "source_dir/source_file"
define asm_source_files !=
	for dir in ${source_dirs}; do
		ls $${dir}/*${asm_ext} 2> /dev/null
	done
endef

# List all header files as "header_dir/header_file"
define header_files !=
	for dir in ${header_dirs}; do
		ls $${dir}/*${h_ext} 2> /dev/null
	done
endef

# List all object files as "build_dir/source_dir/object_file"
define object_files !=
	# Replace source extension for object extension
	for file in ${c_source_files} ${asm_source_files}; do
		file=$${file//${c_ext}/${obj_ext}}
		file=$${file//${asm_ext}/${obj_ext}}
		echo "${build_dir}/$${file}"
	done
endef

# List all object files' headers as "build_dir/info_dir/object_header_file"
define object_header_files !=
	for file in ${object_files} ${elf_file}; do
		# Add info dir after build dir.
		dst=$${file//"${build_dir}"/"${build_dir}/${info_dir}"}
		# Change extension to object header.
		dst=$${dst//"${obj_ext}"/"${obj_header_ext}"}
		dst=$${dst//"${elf_ext}"/"${obj_header_ext}"}
		echo "$${dst}"
	done
endef

# List all disassemblies as "build_dir/info_dir/dasm_file"
define dasm_files !=
	# Change extension to dasm_ext
	for file in ${object_header_files}; do
		file=$${file//${obj_header_ext}/${dasm_ext}}
		echo "$${file}"
	done
endef

#------------------------------------------------------------------------------
# User targets
#------------------------------------------------------------------------------
.PHONY: compile
compile: ${elf_file} ## Compile all source code, generate ELF file.

.PHONY: help
help: ## Display this message.
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

.PHONY: binary
binary: ${bin_file} ## Generate binary file, without ELF headers.

.PHONY: headers
headers: ${object_header_files} ## Generate symbol table and section headers for all object files.

.PHONY: dasm 
dasm: ${dasm_files} ## Generate disassemble for all object files and elf file.

.PHONY: clean
clean: ## Erase contents of build directory.
	if [ -d $${build_dir} ]; then
		rm -R $${build_dir}
		echo -n "All files successfully erased "
		${print_checkmark}
	else
		echo -n "Nothing to erase "
		${print_cross}
	fi

.PHONY: clear
clear: clean ## Same as clean.

.PHONY: run
run: ${elf_file} ## Execute compiled program.
	./$<

#------------------------------------------------------------------------------
# Compilation targets
#------------------------------------------------------------------------------

# Main executable linking
${elf_file}: ${object_files}
	echo -n "Linking everything together... "
	if [ -n "${linker_script}" ]; then
		script="-T ${linker_script}"
	fi

	${linker} ${linker_flags} $${script} -o $@ $^
	${print_checkmark}
	echo "Executable file \"$@\" successfully created."

# Compiling individual object files 
${build_dir}/%${obj_ext}: %.* ${header_files} Makefile
	# Create compilation folders if they don't exist
	for dir in ${source_dirs}; do
		mkdir -p ${build_dir}/$${dir}
	done

	# Add "-I" flag in between header direrctories
	include_headers=""
	for dir in ${header_dirs}; do
		include_headers="$${include_headers} -I $${dir}"
	done
	
	# Actual compiling
	if echo $< | grep "\${c_ext}" &>/dev/null; then
		echo -n "Compiling $< --> $@... "
		${cc} ${compiler_flags} -o $@ -c $${include_headers} $<
	elif echo $< | grep "\${asm_ext}" &>/dev/null; then
		echo -n "Assembling $< --> $@... "
		${as} ${assembler_flags} -o $@ -c $${include_headers} $<
	else
		${print_cross}
		echo "Unrecognized file extension."
		exit 1
	fi
	
	${print_checkmark}

# Print object files' headers
${build_dir}/${info_dir}/%${obj_header_ext}: ${build_dir}/%.o
	for dir in ${source_dirs}; do
		mkdir -p "${build_dir}/${info_dir}/$${dir}"
	done
	echo -n "Printing $< -> $@... "
	${objdump} -x $< > $@
	${print_checkmark}

# Print elf file's header
${build_dir}/${info_dir}/%${obj_header_ext}: ${build_dir}/%.elf
	echo -n "Printing $< -> $@... "
	${objdump} -x $< > $@
	${print_checkmark}

# Print object files' disassembly
${build_dir}/${info_dir}/%${dasm_ext}: ${build_dir}/%.o
	for dir in ${source_dirs}; do
		mkdir -p "${build_dir}/${info_dir}/$${dir}"
	done
	echo -n "Disassembling $< -> $@... "
	${objdump} -d $< > $@
	${print_checkmark}

# Print elf file disassembly
${build_dir}/${info_dir}/%${dasm_ext}: ${build_dir}/%.elf
	echo -n "Disassembling $< -> $@... "
	${objdump} -d $< > $@
	${print_checkmark}

# Copy ELF file into BIN file
${bin_file}: ${elf_file}
	echo -n "Creating binary file $@... "
	${objcopy} -O binary ${elf_file} ${bin_file}
	${print_checkmark}
