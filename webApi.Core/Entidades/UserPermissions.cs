using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class UserPermissions
    {
        public int PermissionId { get; set; } 
      public Roles oRol { get; set; }
        public string ScreenName { get; set; }


    }
}
