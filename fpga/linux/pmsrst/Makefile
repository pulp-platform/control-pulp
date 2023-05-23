
#Simulation
SRCS 		= pmsrst.c

NAME=pmsrst

CC=$(CROSS_COMPILE)gcc
AR=$(CROSS_COMPILE)ar
OB=$(CROSS_COMPILE)objdump

CFLAGS += -Wall -O2 -DPLATFORM=${PLATFORM}

OBJS = $(addsuffix .o, $(basename $(SRCS)))

.PHONY: all build clean deploy dis

all: build

$(NAME): $(SRCS)
	$(CC) $^ -o $@ $(CFLAGS) $(MAKE_FLAGS) $(ADD_COMP_FLAGS)

build: $(NAME)

deploy: build
	scp $(NAME) $(HERO_TARGET_HOST):$(HERO_TARGET_PATH_APPS)/

dis: build
	$(OB) -dS $(NAME) > $(NAME).s

clean:
	-rm -f $(NAME)
