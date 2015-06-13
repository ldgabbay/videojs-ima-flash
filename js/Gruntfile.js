module.exports = function( grunt ) {
    "use strict";

    var library_name = "videojs.ima_flash";
    var filelist = [].concat(["wrap/intro.js"], grunt.file.readJSON("build/filelist.json"), ["wrap/outro.js"]);

    console.log(filelist);

    grunt.initConfig({
        concat: {
            release: {
                src: filelist,
                dest: "build/release/"+library_name+".js",
                options: {
                    process: function(src, filepath) {
                        return src.replace(/\bDEBUG\b/g, 'false');
                    }
                }
            },
            debug: {
                src: filelist,
                dest: "build/debug/"+library_name+".js",
                options: {
                    process: function(src, filepath) {
                        return src.replace(/\bDEBUG\b/g, 'true');
                    }
                }
            }
        },
        uglify: {
            release: {
                src: [ "build/release/"+library_name+".js" ],
                dest: "build/release/"+library_name+".min.js",
                options: {
                    preserveComments: false,
                    sourceMap: "build/release/"+library_name+".min.map",
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

    grunt.registerTask("compile", ["concat:debug", "concat:release", "uglify:release"]);
    grunt.registerTask("default", ["compile"]);
};
