require 'env'

local utils = require 'utils'

local SB = utils.memstorage.SimpleBackend

local MS = utils.memstorage.Memstorage

module( "test_memstorage", package.seeall, lunit.testcase )

function test_memstorage_set_get()
    sb = SB{}
    ms = MS(sb)
    ms:set('a', 1)
    ms:set('b', nil)
    ms:set('c', 'foo!')
    ms:set('d', true)

    ms = MS(sb)
    assert_equal(1, ms:get('a'))
    assert_equal(nil, ms:get('b'))
    assert_equal('foo!', ms:get('c'))
    assert_equal(true, ms:get('d'))
end

function test_memstorage_serialize()
    s = utils.memstorage._serialize
    assert_equal('sHello', s('Hello'))
    assert_equal('s', s(''))
    assert_equal('n42', s(42))
    assert_equal('n-42', s(-42))
    assert_equal('0', s(nil))
    assert_equal('b1', s(true))
    assert_equal('b0', s(false))
    assert_error(function () s({}) end)
end

function test_memstorage_deserialize()
    d = utils.memstorage._deserialize
    s = utils.memstorage._serialize
    assert_equal('Hello', d(s('Hello')))
    assert_equal('', d(s('')))
    assert_equal(42, d(s(42)))
    assert_equal(-42, d(s(-42)))
    assert_equal(nil, d(s(nil)))
    assert_equal(true, d(s(true)))
    assert_equal(false, d(s(false)))
    assert_error(function () d('random stuff') end)
    assert_error(function () d('b42') end)
    assert_error(function () d('no') end)
end

function test_memstorage_adapter()
    ada = utils.memstorage.MemstorageAdapter
    sb = SB{}
    ms = MS(sb)
    ms:set('abc.def', 1)
    ms:set('def', 2)
    a = ada(ms, 'abc')
    assert_equal(1, a:get('def'))
    a:set('val', 42)
    assert_equal(42, ms:get('abc.val'))
end

