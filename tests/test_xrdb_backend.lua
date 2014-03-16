require 'env'

local utils = require 'utils'

local XB = utils.memstorage.XrdbBackend

module( "test_xrdb_bacend", package.seeall, lunit.testcase )

function test_loading()
    xb = XB('Xstorage.AWM_test')
    xb:set('a', 'b')
    xb:set('c', 'd')
    xb:set('', '42')
    tbl = xb:load()
    assert_equal('b', tbl.a)
    assert_equal('d', tbl.c)
    assert_equal('42', tbl[''])

    xb:set('a', '136')
    tbl = xb:load()
    assert_equal('136', tbl.a)
end
