const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./app/views/**/public.html.erb",
    "./app/views/static/**/*.html.erb",
    "./app/views/shared/**/*.html.erb",
    "./app/views/people/_form_public.html.erb",
  ],
  theme: {
    extend: {
      colors: {
        purple: "#6A00FF",
        red: "#FF0000",
        green: "#75E045",
        yellow: "#FFE90D",
        darkblue: "#06002C",
      },
      fontSize: {
        "2xs": ".6875rem",
      },
      fontFamily: {
        sans: ["Mona Sans", ...defaultTheme.fontFamily.sans],
        mono: ["VCR OSD Mono", ...defaultTheme.fontFamily.mono],
      },
      opacity: {
        2.5: "0.025",
        7.5: "0.075",
        15: "0.15",
      },
      boxShadow: {
        DEFAULT: '4px 4px white',
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            h1: {
              fontFamily: "VCR OSD Mono",
            },
            h2: {
              fontFamily: "VCR OSD Mono",
            },
            h3: {
              fontFamily: "VCR OSD Mono",
            },
            h4: {
              fontFamily: "VCR OSD Mono",
            },
            h5: {
              fontFamily: "VCR OSD Mono",
            },
            h6: {
              fontFamily: "VCR OSD Mono",
            },
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
