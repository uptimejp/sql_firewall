############
sql_firewall
############

Overview
========

sql_firewall_ is a PostgreSQL_ extension which is intended to protect
database from SQL injections or unexpected queries.

sql_firewall module learns queries which can be executed, and
prevents/warns on executing queries which are not found in the learned
firewall rule.

How it works
------------

sql_firewall can take one of four modes specified in
sql_firewall.firewall parameter: "learning", "enforcing",
"permissive" and "disabled".

In the "learning" mode, sql_firewall collects pairs of "userid" and
"queryid" associated with the executed queries. "queryid" is
calculated based on a parse tree, similar to pg_stat_statements.

In the "enforcing" mode, sql_firewall checks whether queries are in
the list of collected pairs of "userid" and "queryid", the firewall
rules. When a query not in the firewall rules comes in, sql_firewall
produces an error with the message to prevent execution.

In the "permissive" mode, sql_firewall checks queries as well, but
allows to execute even not in the firewall rules. And produces
warnings if the queries are not in the rules.


Installation
------------

sql_firewall can be built as a PostgreSQL extension.

.. code:: sh

  $ export PATH=$PGHOME/bin:$PATH
  $ export USE_PGXS=1
  $ make
  $ sudo make install


Configuration
-------------

Add the following to your ``$PGDATA/postgresql.conf``:

.. code::

   shared_preload_libraries = 'sql_firewall'
   sql_firewall.firewall = 'learning'

Then restart PostgreSQL:

.. code:: sh

   $ pg_ctl -D $PGDATA restart

Finally add the sql_firewall extension to your database:

.. code::

   $ psql mydb
   mydb=# create extension sql_firewall;

sql_firewall would check all queries incoming to not only the specific
database where the module is installed, but all the databases in the
entire PostgreSQL cluster.

Even though, the views and functions in the module would be available
only on the installed database.


GUC Parameters
--------------

shared_preload_libraries
^^^^^^^^^^^^^^^^^^^^^^^^

sql_firewall module needs to be loaded in the
shared_preload_libraries parameter as following:

.. code::

  shared_preload_libraries = 'sql_firewall'

.. admonition:: Note for developers

  pg_stat_statements built with ``--enable-cassert`` causes assert 
  when queryId already has non-zero value.

  So, to use both pg_stat_statements and sql_firewall at the same
  time, pg_stat_statements needs to be loaded prior to sql_firewall
  in the shared_preload_libraries parameter as following.

  ``shared_preload_libraries = 'pg_stat_statements,sql_firewall'``

  Then, sql_firewall can skip queryId calculation if queryId is
  already set by pg_stat_statements, and avoid the assert.

sql_firewall.firewall
^^^^^^^^^^^^^^^^^^^^^

``sql_firewall.firewall`` is able to take one of the following values:
'disabled', 'learning', 'permissive' and 'enforcing'.
The default value is 'disabled'.

sql_firewall.max
^^^^^^^^^^^^^^^^

Number of queries the SQL Firewall can learn.
It can take an int value between 100 and INT_MAX.
The default value is 5000.
The queries which exceed this value in the "learning" mode would never
be learned.


Functions
---------

sql_firewall_reset()
^^^^^^^^^^^^^^^^^^^^

``sql_firewall_reset()`` clears the firewall rules.

This function is available only under the disabled mode with
superuser privilege.

sql_firewall_stat_reset()
^^^^^^^^^^^^^^^^^^^^^^^^^

``sql_firewall_reset()`` clears the counters of warning and error. Only
available with superuser privilege.

sql_firewall_export_rule('/path/to/rule.txt')
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``sql_firewall_export_rule()`` writes the firewall rules in the
specified CSV file.

This function is available only under the disabled mode with
superuser privilege.

sql_firewall_import_rule('/path/to/rule.txt')
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``sql_firewall_import_rule()`` reads the firewall rules from the
specified CSV file.

This function is available only under the disabled mode with
superuser privilege.


Views
-----

sql_firewall.sql_firewall_statements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``sql_firewall_statements`` view shows the firewall rules and execution
counter for each query.

.. code::

    postgres=# select * from sql_firewall.sql_firewall_statements;
     userid |  queryid   |              query              | calls
    --------+------------+---------------------------------+-------
         10 | 3294787656 | select * from k1 where uid = ?; |     4
    (1 row)
    
    postgres=#

sql_firewall.sql_firewall_stat
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

sql_firewall_stat view has two couters: "sql_warning" and
"sql_error".

"sql_warning" shows number of executed queries with warnings in the
"permissive" mode.

"sql_error" shows number of prevented queries in the "enforcing"
mode.

..code::

    postgres=# select * from sql_firewall.sql_firewall_stat;
     sql_warning | sql_error
    -------------+-----------
               2 |         1
    (1 row)
    
    postgres=# 


Examples
--------

Permissive mode
^^^^^^^^^^^^^^^

.. code::

    postgres=# select * from sql_firewall.sql_firewall_statements;
    WARNING:  Prohibited SQL statement
     userid |  queryid   |              query              | calls
    --------+------------+---------------------------------+-------
         10 | 3294787656 | select * from k1 where uid = 1; |     1
    (1 row)
    
    postgres=# select * from k1 where uid = 1;
     uid |    uname
    -----+-------------
       1 | Park Gyu-ri
    (1 row)
    
    postgres=# select * from k1 where uid = 3;
     uid |   uname
    -----+-----------
       3 | Goo Ha-ra
    (1 row)
    
    postgres=# select * from k1 where uid = 3 or 1 = 1;
    WARNING:  Prohibited SQL statement
     uid |     uname
    -----+----------------
       1 | Park Gyu-ri
       2 | Nicole Jung
       3 | Goo Ha-ra
       4 | Han Seung-yeon
       5 | Kang Ji-young
    (5 rows)
  
    postgres=# 

Enforcing mode
^^^^^^^^^^^^^^

.. code::

    postgres=# select * from k1 where uid = 3;
     uid |   uname
    -----+-----------
       3 | Goo Ha-ra
    (1 row)
    
    postgres=# select * from k1 where uid = 3 or 1 = 1;
    ERROR:  Prohibited SQL statement
    postgres=# 


Authors
-------

`Satoshi Nagayasu <mailto:snaga@uptime.jp>`_

.. _sql_firewall: https://github.com/uptimejp/sql_firewall
.. _PostgreSQL: http://www.postgresql.org/
