module.exports = function( grunt ) {
    "use strict";

    var library_name = "videojs.ima_flash";
    var filelist = [].concat(["wrap/intro.js"], grunt.file.readJSON("build/filelist.json"), ["wrap/outro.js"]);

    console.log(filelist);

    grunt.initConfig({
        concat: {
            main: {
                src: filelist,
                dest: "build/dist/"+library_name+".js"
            }
        },
        uglify: {
            main: {
                src: [ "build/dist/"+library_name+".js" ],
                dest: "build/dist/"+library_name+".min.js",
                options: {
                    preserveComments: false,
                    sourceMap: "build/dist/"+library_name+".min.map",
                    sourceMappingURL: library_name+".min.map",
                    report: "min",
                    beautify: {
                        ascii_only: true
                    },
                    banner: "/*  */",
                    compress: {
                        hoist_funs: false,
                        loops: false,
                        unused: false
                    }
                }
            }
        }
    });

    grunt.loadNpmTasks("grunt-contrib-concat");
    grunt.loadNpmTasks("grunt-contrib-uglify");

    grunt.registerTask("compile", ["concat:main", "uglify:main"]);
    grunt.registerTask("default", ["compile"]);
};
