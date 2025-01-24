return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            linters_by_ft = {
                python = { "pylint" },
            },
        },
    },
}
