local cli = require('cli')

require('tap')(function (test)

  test("testing cli", function()

    local ran = false
    cli.addCommand("test",function(params,flags)
      assert(params[1] == "param","first parameter is wrong")
      assert(params[2] == "param2","second parameter is wrong")
      assert(flags[1] == "flag","first flag is wrong")
      assert(flags[2] == "flag2","second flag is wrong")
      ran = true
    end)
    cli.run({"test","-flag","param","-flag2","param2"})
    assert(ran,"the correct function was ran")
  end)
end)
