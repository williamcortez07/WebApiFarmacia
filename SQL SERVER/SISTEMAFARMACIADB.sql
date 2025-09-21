-- Crear la base de datos
CREATE DATABASE PHARMACYSYSTEMDB;
GO

USE PHARMACYSYSTEMDB;
GO

-- =========================
-- TABLAS PRINCIPALES
-- =========================
--tabla Marcas
CREATE TABLE Brands (
    BrandId INT PRIMARY KEY IDENTITY,
    BrandName NVARCHAR(100) NOT NULL,
    BrandDescription NVARCHAR(500),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1
);
GO
--tabla correspondiente a proveedores
CREATE TABLE Suppliers (
    SupplierId INT PRIMARY KEY IDENTITY,
    SupplierName NVARCHAR(100) NOT NULL,
    RNC NVARCHAR(50), -- Registro nacional de contribuyente, cedula no porque puede ser una farmaceutica el proveedor
    Mail NVARCHAR(100),
    SupplierPhone NVARCHAR(20),
    SupplierAddress NVARCHAR(100),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1
);
GO
--tabla correspondiente a categorias
CREATE TABLE Categories(
    CategoryId INT PRIMARY KEY IDENTITY,
    CategoryName NVARCHAR(100) NOT NULL,
    CategoryDescription NVARCHAR(200),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1
);
GO
--tabla correspondiente a las presentaciones de los fármacos o productos
CREATE TABLE Presentations (
    PresentationId INT PRIMARY KEY IDENTITY(1,1),
    PresentationDescription NVARCHAR(100),
    UnitMeasure NVARCHAR(50),
    quantity NVARCHAR(50),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1
);
GO
-- tabla correspondiente a las concentraciones de los productos
CREATE TABLE Concentration (
    ConcentrationId INT PRIMARY KEY IDENTITY(1,1),
    Volume NVARCHAR(50),
    Porcentage NVARCHAR(50),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1
);
GO


--tabla correspondiente a productos
CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductTradeName NVARCHAR(100) NOT NULL,
    ProductGenericName NVARCHAR(100),
    CategoryId INT,
    SalePrice DECIMAL(10,2),
    PurchasePrice DECIMAL(10,2),
    PresentationId INT,
    ConcentrationId INT,
    SupplierId INT,
    BrandId INT,
    CriticalStock INT,  -- NUEVO: stock mínimo permitido
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1,
    FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    FOREIGN KEY (PresentationId) REFERENCES Presentations(PresentationId),
    FOREIGN KEY (ConcentrationId) REFERENCES Concentration(ConcentrationId),
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
    FOREIGN KEY (BrandId) REFERENCES Brands(BrandId)

);
GO

--tabla correspondientes a lotes
CREATE TABLE ProductBatches (
    BatchId INT PRIMARY KEY IDENTITY(1,1),
    BatchNumber NVARCHAR(50), -- en realidad es el codigo del lote auque number esta bien.
    ManufacturingDate DATETIME,
    ExpirationDate DATETIME,         -- NUEVO
    Quantity INT,                -- NUEVO
    ProductId INT,
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1,
FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
    
);
GO

--tabla correspondientes a roles
CREATE TABLE Roles(
RolId INT PRIMARY KEY IDENTITY,
RolDescription NVARCHAR(100),
CreationDate DATETIME DEFAULT GETDATE(),
)

Go

--tabla correspondientes a permisos de los usuarios
CREATE TABLE UserPermissions(
PermissionId INT PRIMARY KEY IDENTITY,
RolId INT REFERENCES Roles(RolId),
ScreenName NVARCHAR(85),
CreationDate DATETIME DEFAULT GETDATE()
)
Go

--tabla correspondientes a Usuarios
CREATE TABLE Users(
UserId INT PRIMARY KEY IDENTITY,
UserName NVARCHAR(100),
UserLastName NVARCHAR(100),
UserPassword NVARCHAR(250),
Mail NVARCHAR(100),
UserPhone NVARCHAR(30),
RolId INT REFERENCES Roles(RolId),
RegisteredDate DATETIME DEFAULT GETDATE(),
Isactive BIT DEFAULT 1,
)

Go
-- =========================
-- STOCK
-- =========================
--tabla correspondientes a las existencias
CREATE TABLE Stock (
    StockId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT,
    AvailableQuantity INT,
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (BatchId) REFERENCES ProductBatches(BatchId)
);
GO

--tabla correspondiente a la baja
CREATE TABLE LowInventory(
    LowId INT PRIMARY KEY IDENTITY(1,1),
    BatchId INT,
    Quantity INT,
    ProductId INT REFERENCES Products(ProductId), 
    UserId INT REFERENCES Users(UserId),
    Reason NVARCHAR(500),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (BatchId) REFERENCES ProductBatches(BatchId)
);
GO

-- =========================
-- COMPRAS Y VENTAS
-- =========================


--tabla correspondiente a compras 
CREATE TABLE Purchases (
    PurchaseId INT PRIMARY KEY IDENTITY(1,1),
    SupplierId INT,
    ProductId INT,
    UserId INT REFERENCES Users(UserId),
    Total DECIMAL(10,2),
    Observations NVARCHAR(200),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
   FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
);
GO

--tabla correspondiente a los detalles de las compras
CREATE TABLE PurchasingDetail (
    PurchaseDetailId INT PRIMARY KEY IDENTITY(1,1),
    PurchaseId INT,
    BatchId INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    TotalPrice DECIMAL(10,2),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (PurchaseId) REFERENCES Purchases(PurchaseId),
    FOREIGN KEY (BatchId) REFERENCES ProductBatches(BatchId)
);
GO

--tabla correspondiente a facturas
CREATE TABLE Invoices (
    InvoiceId INT PRIMARY KEY IDENTITY(1,1),
    ClientName NVARCHAR(100),
    ProductId INT,
    UserId INT REFERENCES Users(UserId),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    SubTotal DECIMAL(10,2),
    Discount DECIMAL(10,2),
    Total DECIMAL(10,2),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
);
GO

--Tabla correspondiente al método de pago
CREATE TABLE PaymentMethod (
    PaymentMethodId INT PRIMARY KEY IDENTITY(1,1),
    MethodDescription NVARCHAR(50),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    Isactive BIT DEFAULT 1,
);
GO

--Tabla correspondiente a DetalleVentas
CREATE TABLE SalesDetails (
   SalesDetailId INT PRIMARY KEY IDENTITY(1,1),
    InvoiceId INT,   
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    TotalPrice DECIMAL(10,2),
    PaymentMethodId INT,
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId),   
    FOREIGN KEY (PaymentMethodId) REFERENCES PaymentMethod(PaymentMethodId)
);
GO

-- taba correspondiente a detalles de la facturas
CREATE TABLE InvoicesDetails(
    InvoicesDetailId INT PRIMARY KEY IDENTITY(1,1),
    Quantity INT,
    TotalPrice DECIMAL(10,2),
    InvoiceId INT,
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId)
);
GO
-- =========================
-- MOVIMIENTOS, DEVOLUCIONES
-- =========================


--Tabla correspondinete a los moviminetos en el inventario
CREATE TABLE Movements (
    MovementId INT PRIMARY KEY IDENTITY(1,1),
    ProductId INT,
    MovementType NVARCHAR(50),
    Quantity INT,
    UserId INT REFERENCES Users(UserId),
    BatchId INT REFERENCES ProductBatches(BatchId),
    Remarks NVARCHAR(200),
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);
GO

-- Tabla correspondiente a Maestro devolucion
CREATE TABLE MasterReturn (  -- NUEVO
    MasterReturnId INT PRIMARY KEY IDENTITY(1,1),
    Reason NVARCHAR(200),
    ReturnPolicy NVARCHAR(200)
    
);

GO

--Tabla correspondiente a devoluciones
CREATE TABLE ProductReturns (
    ReturnId INT PRIMARY KEY IDENTITY(1,1),
    ReturnType NVARCHAR(50),
    ReturnDescription NVARCHAR(200),
    InvoiceId INT,
    ProductId INT,
    MasterReturnId INT,   -- NUEVO vínculo con maestro
    RegisteredDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (InvoiceId) REFERENCES Invoices(InvoiceId),
    FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    FOREIGN KEY (MasterReturnId) REFERENCES MasterReturn(MasterReturnId)

);

GO

--tabla que hace una relacion entre marca y proveedores
CREATE TABLE SupplierBrand(
BrandId int,
SupplierId int,
ISMainSupplier	BIT DEFAULT 0,
PRIMARY KEY (BrandId, SupplierId),
FOREIGN KEY (BrandId) REFERENCES Brands (BrandId),
FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId)
);
GO  



/*
-- Índices para mejorar el rendimiento
CREATE INDEX [IX_Producto_Nombre] ON [dbo].[Producto]([NombreComercial], [NombreGenerico]);
CREATE INDEX [IX_Producto_Categoria] ON [dbo].[Producto]([IdCategoria]);
CREATE INDEX [IX_MovimientoInventario_Producto] ON [dbo].[MovimientoInventario]([IdProducto]);
CREATE INDEX [IX_MovimientoInventario_Fecha] ON [dbo].[MovimientoInventario]([Fecha]);
CREATE INDEX [IX_Factura_Fecha] ON [dbo].[Factura]([Fecha]);
CREATE INDEX [IX_Factura_Cliente] ON [dbo].[Factura]([Cliente]);
CREATE INDEX [IX_DetalleFactura_Producto] ON [dbo].[DetalleFactura]([IdProducto]);

*/
