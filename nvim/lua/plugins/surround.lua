-- <leader>ss to add surround, <leader>sst to add surround with tag
return {
    {
        "echasnovski/mini.surround",
        version = false,
        opts = {
            mappings = {
                add = "<leader>ss",
                replace = "<leader>sr",
            },
        },
    },
}
