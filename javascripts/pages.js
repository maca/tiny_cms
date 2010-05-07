
(function($){
  $(function () {
    $("#page-creation").dialog({
      autoOpen : false,
      modal    : true
    });

    $('#pages-tree').tree({
      ui : {
        theme_name : 'apple',
        dots : true
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
                TREE_OBJ.create({ data : 'Index', attributes : {rel : 'page'}}, TREE_OBJ.get_node(NODE[0])); 
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
                TREE_OBJ.create({ data : 'Nueva sección', attributes : {rel : ''}}, TREE_OBJ.get_node(NODE[0])); 
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
          url : '/pages.json'
        }
      },

      callback : {
        beforecreate : function(node, ref, type, tree_obj){
          var ref_node, title, permalink, valid, modalDialog;
          
          switch(type)
          {
            case 'before':
            case 'after':
            // Careful
            ref_node = tree_obj.parent(ref);
            break;
            case 'inside':
            ref_node = $(ref);
            break;
          };
                    
          var created_node = tree_obj.get(node);
          var page_data    = created_node.data;
          $.extend(page_data, created_node.attributes);
          
          if (ref_node != -1)
            $.extend(page_data, {parent_id : ref_node.attr('data-node-id')});

          modalDialog = $('#page-creation');
          
          // Reset the form
          modalDialog.find('input').val('');
          modalDialog.find('.labelWithError').removeClass('.labelWithError');
          modalDialog.find('.fieldWithError').removeClass('.fieldWithError');
          modalDialog.find('.formError').detach();
          
          // Attach actions to buttons
          modalDialog.dialog( "option", "buttons", 
            { 
              Ok : function() {
                $.extend(page_data, {
                  title     : modalDialog.find('#title').val(),
                  permalink : modalDialog.find('#permalink').val()
                });
                
                $.ajax({
                  async  : false,
                  type   : 'POST',
                  url    : "/pages.json",
                  data   : {
                    _method : "post",
                    page    : page_data
                  },
                  error  : function(response, status) {
                    $.each(jQuery.parseJSON(response.responseText), function(index, value){
                      modalDialog.find('[for=' + value[0] + ']').addClass('labelWithError');
                      modalDialog.find('#' + value[0]).addClass('fieldWithError').after('<div class="formError">' + value[1] + '</div>');
                    });
                  },
                  success : function(data, status) {
                    var attrs    = data.attributes;
                    var new_node = $(node);

                    new_node.attr('data-node-id',   attrs['data-node-id']);
                    new_node.attr('data-path',      attrs['data-path']);
                    new_node.attr('data-permalink', attrs['data-permalink']);

                    new_node.children('a').html('<ins/>' + data.data);
                    
                    valid = true;
                    modalDialog.dialog("close");
                  },
                  dataType : 'json'
                });
              },   
              Cancel : function() { 
                modalDialog.dialog("close");
              } 
          });
          
          modalDialog.bind( "dialogclose", function(event, ui) { 
            if(!valid) { tree_obj.remove(node); } 
          }).dialog('open');

          return true;
        },
        
        onmove : function(node, ref, type, tree_obj){
          var ref_node, children;
          var child_ids = [];
          
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
            child_ids.push(children[i].attributes['data-node-id']);
          };
                    
          $.ajax({
            type : 'POST',
            url : "/pages/" + ref_node.attributes['data-node-id'] + '.json',
            data : {
               _method : 'put',
               page : { child_ids : child_ids }
            },
            dataType : 'json'
          });
        },

        onrename : function(node, tree_obj, rollback){
          $.ajax({
            type : 'PUT', 
            url : "/pages/" + $(node).attr('data-node-id') + '.json',
            data : {
               _method : 'put',
               page : { title : tree_obj.get(node).data.title}
            },
            dataType : 'json'
          });
        },

        ondelete : function(node){
          $.ajax({
            type : 'POST',
            url : "/pages/" + $(node).attr('data-node-id') + '.json',
            data : { _method : 'delete' },
            dataType : 'json'
          });
        }
      }
    });
  
    $("#new-node").click(function(){
      $.tree.focused().create({ data : "index", attributes : {rel : 'page'}}, -1);
      return false;
    });
    $("#new-section").click(function(){
      $.tree.focused().create({ data : "index", attributes : {rel : ''}}, -1);
      return false;
    });
  });
})(jQuery);