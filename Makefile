# contrib/sql_firewall/Makefile

MODULE_big = sql_firewall
OBJS = sql_firewall.o

EXTENSION = sql_firewall
DATA = sql_firewall--0.8.sql

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/sql_firewall
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
