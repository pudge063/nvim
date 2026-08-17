return {
    "mfussenegger/nvim-dap",
    dependencies = {
        { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
        "mfussenegger/nvim-dap-python",
    },
    keys = {
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
        {
            "<leader>dB",
            function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
            desc = "Conditional breakpoint",
        },
        { "<leader>dc", function() require("dap").continue() end, desc = "Debug: continue/start" },
        { "<leader>di", function() require("dap").step_into() end, desc = "Debug: step into" },
        { "<leader>do", function() require("dap").step_over() end, desc = "Debug: step over" },
        { "<leader>dO", function() require("dap").step_out() end, desc = "Debug: step out" },
        { "<leader>dt", function() require("dap").terminate() end, desc = "Debug: terminate" },
        { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: toggle REPL" },
        { "<leader>du", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        dapui.setup()
        dap.listeners.after.event_initialized["dapui_config"] = dapui.open
        dap.listeners.before.event_terminated["dapui_config"] = dapui.close
        dap.listeners.before.event_exited["dapui_config"] = dapui.close

        -- Python: debugpy installed by mason-tool-installer (see lsp.lua),
        -- venv path is mason's fixed install layout.
        require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")

        -- C/C++: gdb's native DAP mode (gdb >= 12, `gdb -i=dap`), no extra
        -- adapter binary needed beyond gdb itself.
        dap.adapters.gdb = {
            type = "executable",
            command = "gdb",
            args = { "-i", "dap" },
        }

        dap.configurations.c = {
            {
                name = "Launch",
                type = "gdb",
                request = "launch",
                program = function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
                cwd = "${workspaceFolder}",
                stopAtBeginningOfMainSubprogram = false,
            },
            {
                -- Embedded: attach gdb to an already-running gdbserver stub,
                -- e.g. `openocd -f <cfg>` (port 3333) or `JLinkGDBServer` (port 2331).
                -- Flash the target first — this only attaches for debugging.
                name = "Attach to remote target (OpenOCD/J-Link gdbserver)",
                type = "gdb",
                request = "attach",
                target = function()
                    return vim.fn.input("gdbserver address: ", "localhost:3333")
                end,
                program = function()
                    return vim.fn.input("Path to ELF (with debug symbols): ", vim.fn.getcwd() .. "/", "file")
                end,
                cwd = "${workspaceFolder}",
            },
        }
        dap.configurations.cpp = dap.configurations.c
    end,
}
