default:
	@fpm run 

gdb:
	@MALLOC_CHECK_=2 fpm run --flag   -g --flag   -fsanitize=address\
	                         --c-flag -g --c-flag -fsanitize=address

release:
	@fpm run --flag   -fuse-ld=mold --flag   -O3 --flag   -march=native --flag   -mtune=native \
	         --c-flag -fuse-ld=mold --c-flag -O3 --c-flag -march=native --c-flag -mtune=native

.PHONY: test
test:
	fpm test

testgdb:
	@MALLOC_CHECK_=2 fpm test --flag   -g --flag   -fsanitize=address\
	                          --c-flag -g --c-flag -fsanitize=address
	
# Use this if the vscode extension gives up.
clean:
	@./scripts/clear_mod_files.sh
	@./scripts/remove_build_folder.sh


#? Leaving this in for when polymorphic types are implemented.
# --compiler flang-new 
