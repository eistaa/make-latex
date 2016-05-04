
include conf.mk

## -------------------------------------

# programs
BIBER     = biber
CMP       = cmp
CP        = cp -p
MAKEINDEX = makeindex
MKDIR     = mkdir -p
MV        = mv
PDFLATEX  = pdflatex
RM        = rm -f
TOUCH     = touch

ifndef $(OUT_NAME)
    OUT_NAME = $(patsubst %.tex,%,$(MAIN_TEX))
endif

gen_main_aux_1 := $(patsubst %.tex,$(BUILD_DIR)/%.aux,$(MAIN_TEX))
gen_main_aux_2 := $(gen_main_aux_1).2
gen_main_aux_3 := $(gen_main_aux_1).3
gen_bbl_file   := $(BUILD_DIR)/$(OUT_NAME).bbl

compile_command = TEXMFOUTPUT=$(BUILD_DIR) $(PDFLATEX) -interaction batchmode -output-directory $(BUILD_DIR) -jobname $(OUT_NAME) $(MAIN_TEX)

## -------------------------------------

.PHONY: all clean
.NOTPARALLEL:  # this makefile cannot run parallell

all: $(OUT_NAME).pdf

$(OUT_NAME).pdf: $(BUILD_DIR)/$(OUT_NAME).pdf $(MAIN_TEX) $(BIB_FILE)
	@echo "Copying compiled document ..."
	@$(CP) $(BUILD_DIR)/$(OUT_NAME).pdf .

$(BUILD_DIR)/$(OUT_NAME).pdf: $(MAIN_TEX) $(BIB_FILE) $(gen_main_aux_3) $(gen_bbl_file) | $(BUILD_DIR)

## -----

$(gen_main_aux_1): $(MAIN_TEX) | $(BUILD_DIR)
	@if [ -e $(gen_main_aux_1) ] ; then \
	  $(CP) $(gen_main_aux_1) $(gen_main_aux_2) ; \
	fi
	@echo $(compile_command)
	@$(compile_command) > /dev/null
	@if $(CMP) -s $(gen_main_aux_1) $(gen_main_aux_2) ; then \
	  $(TOUCH) -r $(gen_main_aux_1) $(gen_main_aux_2) ; \
	  $(CP) $(gen_main_aux_2) $(gen_main_aux_3) ; \
	fi

$(gen_main_aux_2): $(MAIN_TEX) $(gen_main_aux_1) $(gen_bbl_file) | $(BUILD_DIR)
	@if [ -e $(gen_main_aux_2) ] && $(CMP) -s $(gen_main_aux_1) $(gen_main_aux_2) ; then \
	  $(CP) $(gen_main_aux_2) $(gen_main_aux_3) ; \
	else \
	  $(CP) $(gen_main_aux_1) $(gen_main_aux_2) ; \
	  echo $(compile_command) > /dev/null ; \
	  $(compile_command) ; \
	  if $(CMP) -s $(gen_main_aux_1) $(gen_main_aux_2) ; then # reached fixpoint \
	    $(CP) $(gen_main_aux_2) $(gen_main_aux_3) ; \
	    $(TOUCH) $(gen_bbl_file) ; \
	  fi ; \
	fi

$(gen_main_aux_3): $(MAIN_TEX) $(gen_main_aux_1) $(gen_main_aux_2) | $(BUILD_DIR)
	@if ! [ -e $(gen_main_aux_3) ] || ! $(CMP) -s $(gen_main_aux_2) $(gen_main_aux_3) ; then \
	  $(CP) $(gen_main_aux_2) $(gen_main_aux_3) ; \
	  $(CP) $(gen_main_aux_1) $(gen_main_aux_2) ; \
	  echo $(compile_command) ; \
	  $(compile_command) > /dev/null ; \
	  $(TOUCH) $(gen_bbl_file) ; \
	fi

## -----

$(gen_bbl_file): $(BIB_FILE) $(gen_main_aux_1)
	@echo $(BIBER) --input-directory $(BUILD_DIR) --output-directory $(BUILD_DIR) $(OUT_NAME)
	@$(BIBER) --input-directory $(BUILD_DIR) --output-directory $(BUILD_DIR) $(OUT_NAME) > /dev/null
	@$(RM) $(gen_main_aux_2) $(gen_main_aux_3)

## -----

$(BUILD_DIR):
	@$(MKDIR) $@

## -----

clean:
	@echo "Cleaning..."
	@$(RM) -r $(BUILD_DIR)
