using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace webApi.Core.Entidades
{
    public class Products
    {
        public int ProductId { get; set; }
        public string ProductTradeName { get; set; }
        public string ProductGenericName { get; set; }
        public Categories oCategory { get; set; }
        public decimal SalePrice { get; set; }
        public decimal PurchasePrice { get; set; } 
        public Presentations oPresentation { get; set; }
        public Concentration oConcentration { get; set; }
        public Suppliers oSupplier { get; set; }
        public Brands oBrand { get; set; }
        public int CriticalStock { get; set; }
        public bool IsActive {  get; set; }  

    }
}
