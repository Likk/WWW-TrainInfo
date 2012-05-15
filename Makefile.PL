use inc::Module::Install;
name 'WWW-TrainInfo';
all_from 'lib/WWW/TrainInfo.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
