using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class PaymentMethod
    {
        public int PaymentMethodId { get; set; }
        public string MethodDescription { get; set; }
        public bool IsActive { get; set; }

    }
}
