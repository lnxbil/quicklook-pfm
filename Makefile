all:
	@echo "-----------------------------------------------------------"
	@echo "This Makefile is a dummy and runs Xcode in command line mode"
	@echo "Compilation starts in 5 seconds"
	@echo "-----------------------------------------------------------"
	@sleep 5
	@/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Quicklook-PFM.xcodeproj -alltargets
