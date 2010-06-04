document.write("<script type='text/javascript' src='/javascripts/jquery-tree/jquery.tree.min.js'></script>");
document.write("<script type='text/javascript' src='/javascripts/jquery-tree/jquery-tree-plugins/jquery.tree.contextmenu.js'></script>");
document.write("<script type='text/javascript' src='/javascripts/jquery-ui-dialog.js'></script>");

document.write("<link rel='stylesheet' href='/stylesheets/jquery-ui/jquery-ui-1.8.1.custom.css' type='text/css' media='screen' charset='utf-8' />");
document.write("<link rel='stylesheet' href='/stylesheets/apple/style.css' type='text/css' media='screen' charset='utf-8' />");

(function($){
  $.fn.pagesTree = function(opts){
    // Deselect
    $(document).click(function(event){
      var nameClicked = $(event.target).parent('a').parent('li[data-node-id]').size() > 0;
      var iconClicked = $(event.target).parent('li[data-node-id]').size() > 0;
      if(!nameClicked && !iconClicked){
        $.tree.focused().deselect_branch($.tree.focused().selected);
      }
    });
    
    this.tree({
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
              label   : opts.translations.actions.new_page, 
              icon    : "create-page",
              visible : function (node, tree_obj) { 
                if(node.length != 1 || node.attr('rel') == 'page') return false;
                  return tree_obj.check("creatable", node); 
              }, 
              
              action  : function (node, tree_obj) {
                tree_obj.create({ data : 'page', attributes : {rel : 'page'}}, tree_obj.get_node(node[0])); 
              }
            },

            'create-section' : {
              label   : opts.translations.actions.new_section, 
              icon    : "create-secction",
              visible : function (node, tree_obj) { 
                if(node.length != 1 || node.attr('rel') == 'page') return false; 
                return tree_obj.check("creatable", node); 
              }, 
              action  : function (node, tree_obj) { 
                tree_obj.create({ data : 'section', attributes : {rel : ''}}, tree_obj.get_node(node[0])); 
              }
            },
            
            'edit-page' : {
              label   : opts.translations.actions.edit, 
              icon    : "create-page",
              visible : function (node, tree_obj) { return true; },
              action  : function (node, tree_obj) {
                window.location = opts.controller + "/" + $(node[0]).attr('data-node-id') + "/edit";
              },
              separator_after : true
            },

            'rename-custom'  : {
              label : opts.translations.actions.rename, 
              icon  : "rename",
              visible : function (node, tree_obj) { 
                if(node.length != 1) return false;
                return tree_obj.check("renameable", node);
              },
              action  : function (node, tree_obj) { 
                tree_obj.rename(node); 
              }
            },

            'remove-custom'  : {
              label : opts.translations.actions.destroy,
              icon  : "remove",
              visible : function (node, tree_obj) { 
                var ok = true; 
                $.each(node, function () { 
                  if(tree_obj.check("deletable", this) == false) {
                    ok = false; 
                    return false; 
                  }
                }); 
                return ok; 
              },

              action  : function (node, tree_obj) { 
                if (confirm(opts.translations.alerts.confirm)) {
                  $.each(node, function () { 
                    tree_obj.remove(this); 
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
            image : '/stylesheets/apple/file.png'
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
          
          var submitForm = function() {
            $.extend(page_data, {
              title     : modalDialog.find('#title').val(),
              permalink : modalDialog.find('#permalink').val()
            });
            
            $.ajax({
              // timeout : 3000,
              async   : false,
              type    : 'POST',
              url     : opts.controller + ".json",
              data    : {
                _method : "post",
                page    : page_data
              },
              error  : function(response, status) {
                $('.formError').detach();
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
          };
          
          $('#page-creation input').keypress(function (e) {  
            if ((e.which == 13) || (e.keyCode == 13)) {  
              submitForm(); 
              return false;  
            } else {  
              return true;  
            }  
          });
          
          // Attach actions to buttons
          modalDialog.dialog( "option", "buttons", 
            { 
              Ok : submitForm,
              Cancel : function() {
                modalDialog.dialog("close");
              } 
          });
          
          modalDialog.bind( "dialogclose", function(event, ui) {
            if(!valid) 
              tree_obj.remove(node);
          }).dialog('open');

          return true;
        },
        
        onmove : function(node, ref, type, tree_obj, rollback){
          var ref_node, children, url, data;
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

          if (ref_node == -1) {
            children = tree_obj.children(-1);
            url      = opts.controller + '/reorder.json';
            $.each(children, function(index, value){ child_ids.push($(value).attr('data-node-id')); });
          } else {
            ref_node = tree_obj.get(ref_node, 'json', {outer_attrib : ['data-node-id']});
            children = ref_node.children;
            url      = opts.controller + "/" + ref_node.attributes['data-node-id'] + '.json';
            $.each(children, function(index, value){ child_ids.push(value.attributes['data-node-id']); });
          }

          $.ajax({
            timeout : 3000,
            type : 'POST',
            url  : url,
            data : {
               _method : 'put',
               page : { child_ids : child_ids }
            }, 
            error : function(response, status){
              if(response.status == 422)
                alert(opts.translations.alerts.duplicate_path);
              $.tree.rollback(rollback);
            },
            dataType : 'json'
          });
        },

        onrename : function(node, tree_obj, rollback){
          $.ajax({
            timeout : 3000,
            type : 'PUT', 
            url : opts.controller + "/" + $(node).attr('data-node-id') + '.json',
            data : {
               _method : 'put',
               page : { title : tree_obj.get(node).data.title}
            },
            error : function(){
              $.tree.rollback(rollback);
            },
            dataType : 'json'
          });
        },

        ondelete : function(node, tree_obj, rollback){
          var id = $(node).attr('data-node-id');
          if (id) {
            $.ajax({
              timeout : 3000,
              type : 'POST',
              url : opts.controller + "/" + $(node).attr('data-node-id') + '.json',
              data : { _method : 'delete' },
              error : function(){
                $.tree.rollback(rollback);
              },
              dataType : 'json'
            });
          }
        },
      
        onselect : function(node){
          if( !($(node).attr('rel') == 'section') )
            $('input#new-node, input#new-section').attr('disabled', true);
          $('input#destroy').removeAttr('disabled');
        },
        
        ondeselect : function() {
          $('input#new-node, input#new-section').removeAttr('disabled');
          $('input#destroy').attr('disabled', true);
        }
      }
    });
  };
})(jQuery);