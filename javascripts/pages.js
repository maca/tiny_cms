
(function($){
  
  $(function () {
    $('#pages-tree').tree({
      ui : {
        theme_name : 'apple',
        dots : false
      },

      plugins : {
        contextmenu : {
          items : {
            rename : false,
            remove : false,
            create : false,

            'create-page' : {
              label   : "Crear página", 
              icon    : "create-page",
              visible : function (NODE, TREE_OBJ) { 
                if(NODE.length != 1 || NODE.attr('rel') == 'page') return false;
                  return TREE_OBJ.check("creatable", NODE); 
              }, 
              
              action  : function (NODE, TREE_OBJ) {
                TREE_OBJ.create({ data : 'Nueva página', attributes : {rel : 'page'}}, TREE_OBJ.get_node(NODE[0])); 
              }
            },

            'create-section' : {
              label   : "Crear sección", 
              icon    : "create-secction",
              visible : function (NODE, TREE_OBJ) { 
                if(NODE.length != 1 || NODE.attr('rel') == 'page') return false; 
                return TREE_OBJ.check("creatable", NODE); 
              }, 
              action  : function (NODE, TREE_OBJ) { 
                TREE_OBJ.create({ data : 'Nueva sección'}, TREE_OBJ.get_node(NODE[0])); 
              },
              separator_after : true
            },

            'rename-custom'  : {
              label : "Renombrar", 
              icon  : "rename",
              visible : function (NODE, TREE_OBJ) { 
                if(NODE.length != 1) return false;
                return TREE_OBJ.check("renameable", NODE);
              },
              action  : function (NODE, TREE_OBJ) { 
                TREE_OBJ.rename(NODE); 
              }
            },

            'remove-custom'  : {
              label : "Eliminar",
              icon  : "remove",
              visible : function (NODE, TREE_OBJ) { 
                var ok = true; 
                $.each(NODE, function () { 
                  if(TREE_OBJ.check("deletable", this) == false) {
                    ok = false; 
                    return false; 
                  }
                }); 
                return ok; 
              },

              action  : function (NODE, TREE_OBJ) { 
                if (confirm('¿Seguro?')) {
                  $.each(NODE, function () { 
                    TREE_OBJ.remove(this); 
                  });
                }; 
              } 
            }
          }
        }
      },

      types : {
        "page" : {
          valid_children : "none",
          icon : {
            image : 'file.png'
          }
        }
      },

      data : {
        type  : 'json',
        async : true,
        opts  : {
          url : '/admin/pages.json'
        }
      },

      callback : {
        beforecreate : function(node, ref, type, tree_obj){
          var ref_node, success;
          
          switch(type)
          {
            case 'before':
            case 'after':
            ref_node = tree_obj.parent(ref);
            break;
            case 'inside':
            ref_node = tree_obj.parent(node);
            break;
          };
          
          var created_node = tree_obj.get(node);
          var page_data    = {parent_id : ref_node.attr('data-node-id')};
          $.extend(page_data, created_node.data, created_node.attributes);
                    
          $.ajax({
            type : 'POST',
            url : "/pages",
            data : { page : page_data },
            success : function(data) {
              //
              created_node.attributes['data-node-id'] = '100';
              success = true;
            },
            contentType : 'application/json'
          });
          return true;
        },
        
        onmove : function(node, ref, type, tree_obj){
          var ref_node, children;
          var children_ids = [];
          
          switch(type)
          {
            case 'before':
            case 'after':
            ref_node = tree_obj.parent(ref);
            break;
            case 'inside':
            ref_node = tree_obj.parent(node);
            break;
          };

          ref_node = tree_obj.get(ref_node, 'json', {outer_attrib : ['data-node-id']});
          children = ref_node.children;
          
          for (i = 0; i < children.length; i++){
            children_ids.push(children[i].attributes['data-node-id']);
          };
                    
          $.ajax({
            type : 'POST',
            url : "/pages/" + ref_node.attributes['data-node-id'],
            data : {
               _method : 'put',
               page : { children_ids : children_ids }
            },
            contentType : 'application/json'
          });
        },

        onrename : function(node){
          $.ajax({
            type : 'POST',
            url : "/pages/" + $(node).attr('data-node-id'),
            data : {
               _method : 'put',
               page : { name : node.innerText }
            },
            contentType : 'application/json'
          });
        },

        ondelete : function(node){
          $.ajax({
            type : 'POST',
            url : "/pages/" + $(node).attr('data-node-id'),
            data : { _method : 'delete' },
            contentType : 'application/json'
          });
        }
      }
    });
  });
})(jQue